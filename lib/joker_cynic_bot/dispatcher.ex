defmodule JokerCynicBot.Dispatcher do
  @moduledoc false
  use ExGram.Bot,
    name: :joker_cynic,
    setup_commands: true

  alias JokerCynicBot.Reply

  command("privacy", description: "Политика конфиденциальности")

  middleware(JokerCynicBot.AddTelemetryDataMiddleware)
  middleware(JokerCynicBot.SaveUpdateMiddleware)
  middleware(ExGram.Middleware.IgnoreUsername)
  middleware(JokerCynicBot.AntispamMiddleware)
  middleware(JokerCynicBot.LoadDataMiddleware)

  @spec bot() :: :joker_cynic
  def bot, do: :joker_cynic

  @spec handle(ExGram.Dispatcher.parsed_message(), ExGram.Cnt.t()) :: ExGram.Cnt.t()
  def handle(message, context) do
    context
    |> Reply.new(message)
    |> execute_command(message)
    |> Reply.execute()

    now = :os.system_time()

    :telemetry.execute([:joker_cynic, :bot], %{handle_time: now - context.extra.received_at}, %{
      message: message,
      context: context
    })

    context
  end

  defp execute_command(%{context: %{middleware_halted: true} = context} = reply, _message) do
    if middleware_reply = context.extra[:middleware_reply] do
      middleware_reply
    else
      %Reply{reply | halt: true}
    end
  end

  defp execute_command(reply, {:command, :privacy, _msg}) do
    JokerCynicBot.PrivacyCommand.call(reply)
  end

  defp execute_command(reply, _msg) do
    %Reply{reply | halt: true}
  end
end
