defmodule AnyTalker.Counters.NikitaCounterJob do
  @moduledoc false
  use Oban.Worker, queue: :default

  alias AnyTalker.Counters.Helpers

  @impl Oban.Worker
  def perform(_job), do: Helpers.send_init_message()
end
