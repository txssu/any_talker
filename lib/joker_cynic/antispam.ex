defmodule JokerCynic.Antispam do
  @moduledoc false

  alias JokerCynic.Accounts.UserCaptcha
  alias JokerCynic.Antispam.KickUserJob
  alias JokerCynic.Repo

  def generate_captcha do
    left = Enum.random(1..9)
    right = Enum.random(1..9)
    answer = to_string(left + right)

    {answer, "#{left} \\+ #{right} \\= ?"}
  end

  def assign_captcha(user_id, chat_id, answer, bot_message_id, join_message_id) do
    captcha =
      JokerCynic.Repo.insert!(%UserCaptcha{
        answer: answer,
        message_ids: [bot_message_id],
        join_message_id: join_message_id,
        chat_id: chat_id,
        user_id: user_id
      })

    %{user_id: user_id, chat_id: chat_id}
    |> KickUserJob.new(schedule_in: 60)
    |> Oban.insert!()

    captcha
  end

  def validate_captcha(user_id, chat_id, text) do
    if captcha = get_captcha(user_id, chat_id) do
      if captcha.answer == text do
        {:ok, captcha}
      else
        {:error, captcha}
      end
    else
      {:ok, nil}
    end
  end

  def add_message_to_delete(captcha, message_id) do
    captcha
    |> Ecto.Changeset.change(%{message_ids: [message_id | captcha.message_ids]})
    |> Repo.update!()
  end

  def delete_captcha(captcha) do
    Repo.delete!(captcha)
  end

  def get_captcha(user_id, chat_id) do
    Repo.get_by(UserCaptcha, user_id: user_id, chat_id: chat_id)
  end
end
