defmodule JokerCynic.Counters.NikitaCounterJob do
  @moduledoc false
  use Oban.Worker, queue: :default

  alias JokerCynic.Counters.Helpers

  @impl Oban.Worker
  def perform(_job), do: Helpers.send_init_message()
end
