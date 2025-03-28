defmodule JokerCynic.Antispam do
  @moduledoc false

  import Ecto.Query
  import JokerCynicBot.MarkdownUtils

  alias JokerCynic.Antispam.Captcha
  alias JokerCynic.Repo

  @spec get_captcha(integer()) :: Captcha.t() | nil
  def get_captcha(id) do
    Repo.get(Captcha, id)
  end

  @spec get_captcha(integer(), integer()) :: Captcha.t() | nil
  def get_captcha(user_id, chat_id) do
    query =
      from c in Captcha,
        where: c.chat_id == ^chat_id and c.user_id == ^user_id,
        order_by: [desc: c.inserted_at],
        limit: 1

    Repo.one(query)
  end

  @spec create_captcha(integer(), String.t(), integer(), integer()) :: {:ok, Captcha.t()} | {:error, Ecto.Changeset.t()}
  def create_captcha(user_id, username, chat_id, join_message_id) do
    {question, answer} = generate_captcha()
    text = format_question(user_id, username, question)
    message = send_message(chat_id, text)

    attrs = %{
      answer: answer,
      user_id: user_id,
      username: username,
      chat_id: chat_id,
      join_message_id: join_message_id,
      captcha_message_id: message.message_id,
      status: :created
    }

    if old_captcha = get_captcha(user_id, chat_id) do
      obsolete_captcha(old_captcha)
    end

    with {:ok, captcha} <- save_captcha(attrs),
         job_attrs = JokerCynic.Antispam.KickUserJob.new(%{"captcha_id" => captcha.id}, schedule_in: 60),
         {:ok, _job} <- Oban.insert(job_attrs) do
      {:ok, captcha}
    end
  end

  defp save_captcha(attrs) do
    %Captcha{}
    |> Captcha.changeset(attrs)
    |> Repo.insert()
  end

  @spec try_resolve_captcha(Captcha.t(), String.t(), integer()) :: Captcha.t()
  def try_resolve_captcha(captcha, user_answer, message_id) do
    status =
      if captcha.answer == user_answer,
        do: :resolved,
        else: :failed

    set_status(captcha, status, message_id: message_id)
  end

  @spec obsolete_captcha(Captcha.t()) :: Captcha.t()
  def obsolete_captcha(captcha) do
    set_status(captcha, :obsoleted)
  end

  @spec time_out_captcha(Captcha.t()) :: Captcha.t()
  def time_out_captcha(captcha) do
    set_status(captcha, :timed_out)
  end

  defp set_status(captcha, status, options \\ []) do
    captcha
    |> Captcha.changeset(%{status: status})
    |> Repo.update!()
    |> execute(options)
  end

  defp execute(%{status: status} = captcha, options) when status in ~w[timed_out failed]a do
    ExGram.ban_chat_member(captcha.chat_id, captcha.user_id, bot: bot())

    resolving_message_id = Keyword.get(options, :message_id)
    join_message_id = if status != :timed_out, do: captcha.join_message_id

    messages_to_delete =
      Enum.reject([resolving_message_id, join_message_id, captcha.captcha_message_id], &is_nil/1)

    ExGram.delete_messages(captcha.chat_id, messages_to_delete, bot: bot())
    captcha
  end

  defp execute(%{status: :resolved} = captcha, options) do
    resolving_message_id = Keyword.fetch!(options, :message_id)
    ExGram.delete_messages(captcha.chat_id, [resolving_message_id, captcha.captcha_message_id], bot: bot())

    send_message(captcha.chat_id, welcome_message(captcha.username, captcha.user_id))

    captcha
  end

  defp execute(%{status: :obsoleted} = captcha, _options) do
    ExGram.delete_message(captcha.chat_id, captcha.captcha_message_id, bot: bot())

    captcha
  end

  defp send_message(chat_id, text) do
    ExGram.send_message!(chat_id, text, parse_mode: "MarkdownV2", bot: bot())
  end

  defp generate_captcha do
    a = Enum.random(1..10)
    b = Enum.random(1..10)

    question = "#{a} + #{b} = ?"
    answer = to_string(a + b)

    {question, answer}
  end

  defp format_question(user_id, username, question) do
    ~i"""
    [#{username}](tg://user?id=#{user_id}), у тебя ровно одна минута, чтобы решить капчу:
    #{question}

    Если ты отправишь что\-то кроме ответа на капчу, я кикну тебя из чата\.
    """
  end

  defp welcome_message(username, user_id) do
    ~i"""
    Закуриваю 🚬, выдыхаю дым и с ехидной улыбкой шепчу: “Добро пожаловать в этот цирк, [#{username}](tg://user?id=#{user_id}), здесь каждый клоун думает, что он главная звезда\.”
    """
  end

  defp bot, do: JokerCynicBot.bot()
end
