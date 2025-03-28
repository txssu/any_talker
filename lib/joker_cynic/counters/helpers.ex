defmodule JokerCynic.Counters.Helpers do
  @moduledoc false
  import ExGram.Dsl.Keyboard

  alias JokerCynic.Cache
  alias JokerCynic.Counters.CounterVerificationTimeoutJob

  require ExGram.Dsl.Keyboard

  @nikita_id Application.compile_env!(:joker_cynic, :nikita_id)
  @nikita_chat_id Application.compile_env!(:joker_cynic, :nikita_chat_id)
  @counter_timeout_min Application.compile_env!(:joker_cynic, :nikita_counter_timeout_min)

  @spec nikita_id?(integer()) :: boolean()
  def nikita_id?(id) do
    id == @nikita_id
  end

  @spec send_init_message() :: :ok
  def send_init_message do
    markup =
      keyboard :inline do
        row do
          button("Да", callback_data: "counter-yes")
          button("Нет", callback_data: "counter-no")
        end
      end

    message =
      ExGram.send_message!(@nikita_chat_id, init_text(),
        reply_markup: markup,
        parse_mode: "MarkdownV2",
        bot: JokerCynicBot.bot()
      )

    mark_as_unanswered(message.message_id)

    timeout_at = DateTime.add(DateTime.utc_now(), @counter_timeout_min, :minute)

    %{message_id: message.message_id}
    |> CounterVerificationTimeoutJob.new(scheduled_at: timeout_at)
    |> Oban.insert()

    :ok
  end

  @spec answer_counter(integer(), atom(), atom()) :: :ok
  def answer_counter(message_id, updated_by, summary_message_type \\ :normal) do
    updated_text = get_updated_text(updated_by)

    ExGram.edit_message_text(
      updated_text,
      chat_id: @nikita_chat_id,
      message_id: message_id,
      parse_mode: "MarkdownV2",
      bot: JokerCynicBot.bot()
    )

    new_message_text = get_summary_text(summary_message_type)

    ExGram.send_message(@nikita_chat_id, new_message_text, bot: JokerCynicBot.bot())

    mark_as_answered(message_id)

    :ok
  end

  @spec mark_as_unanswered(integer()) :: :ok
  def mark_as_unanswered(message_id), do: Cache.put(message_id, false)

  @spec mark_as_answered(integer()) :: :ok
  def mark_as_answered(message_id), do: Cache.put(message_id, true)

  @spec answered?(integer()) :: boolean()
  def answered?(message_id), do: Cache.get(message_id)

  defp init_text do
    "[Никита](tg://user?id=#{@nikita_id}), ты сегодня занялся сексом?"
  end

  defp get_updated_text(:timeout), do: "#{init_text()}\nВремя на ответ истекло\\."
  defp get_updated_text(:nikita), do: "#{init_text()}\nОтвет дан\\."

  defp get_summary_text(:normal), do: "Никита. #{nikita_counter()}"

  defp get_summary_text(:lie),
    do: "Никита, зачем ты ответил, что у тебя был секс? Ты хотя бы себя не обманывай.\n#{nikita_counter()}"

  defp nikita_counter do
    days = Date.diff(Date.utc_today(), ~D[2005-02-10])

    "День без секса #{days}."
  end
end
