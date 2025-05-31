defmodule AnyTalker.Counters.CounterVerificationTimeoutJob do
  @moduledoc false
  use Oban.Worker, queue: :default

  import AnyTalker.Counters.Helpers

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"message_id" => message_id}}) do
    if not answered?(message_id) do
      answer_counter(message_id, :timeout)
    end

    :ok
  end
end
