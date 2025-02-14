defmodule JokerCynic.Counters.CounterVerificationTimeoutJob do
  @moduledoc false
  use Oban.Worker, queue: :default

  import JokerCynic.Counters.Helpers

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"text" => text, "chat_id" => chat_id, "message_id" => message_id}}) do
    answer_counter(chat_id, message_id, "#{text}\nВремя на ответ истекло.", "Никита. #{nikita_counter()}")

    :ok
  end
end
