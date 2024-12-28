defmodule JokerCynicBot.Reply do
  @moduledoc false

  use TypedStruct

  require Logger

  typedstruct do
    field :text, String.t()
    field :direct_message_only, boolean(), default: false
    field :halt, boolean(), default: false

    field :message, ExGram.Dispatcher.parsed_message()
    field :context, ExGram.Cnt.t()
  end

  @spec new(ExGram.Cnt.t(), ExGram.Dispatcher.parsed_message()) :: __MODULE__.t()
  def new(context, message) do
    %__MODULE__{message: message, context: context}
  end

  @spec execute(t()) :: any()
  def execute(%__MODULE__{} = reply) do
    reply
    |> check_halt()
    |> check_direct_message_only()
    |> send_reply()
  end

  defp check_halt(%__MODULE__{halt: true} = reply), do: {:halt, reply}
  defp check_halt(%__MODULE__{halt: false} = reply), do: {:cont, reply}

  defp check_direct_message_only({:halt, reply}), do: {:halt, reply}

  defp check_direct_message_only({:cont, %__MODULE__{} = reply}) do
    if reply.direct_message_only and reply.context.update.message.chat.type == "private" do
      {:cont, reply}
    else
      {:halt, nil}
    end
  end

  defp send_reply({:halt, %__MODULE__{}}), do: :ok

  defp send_reply({:cont, %__MODULE__{context: context, text: text}}) do
    case ExGram.send_message(context.update.message.chat.id, text, bot: JokerCynicBot.Dispatcher.bot()) do
      {:ok, _message} -> :ok
      {:error, error} -> Logger.error("Error sending message: #{error.message}")
    end
  end
end
