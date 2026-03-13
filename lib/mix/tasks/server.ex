defmodule Mix.Tasks.Server do
  @shortdoc "Starts the Phoenix server and Telegram bot"
  @moduledoc "Starts the application with both HTTP server and Telegram bot polling enabled."

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    Application.put_env(:any_talker, :start_bot, true, persistent: true)
    Application.put_env(:phoenix, :serve_endpoints, true, persistent: true)
    Mix.Tasks.Run.run(run_args() ++ args)
  end

  defp run_args, do: if(iex_running?(), do: [], else: ["--no-halt"])

  defp iex_running?, do: Code.ensure_loaded?(IEx) and IEx.started?()
end
