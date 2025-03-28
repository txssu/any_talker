defmodule JokerCynicBot.Reply do
  @moduledoc false

  use TypedStruct

  alias ExGram.Model.Message

  require Logger

  typedstruct do
    field :text, String.t()
    field :direct_message_only, boolean(), default: false
    field :halt, boolean(), default: false
    field :markdown, boolean(), default: false
    field :on_sent, (Message.t() -> any()) | nil
    field :as_reply?, boolean()

    field :message, ExGram.Dispatcher.parsed_message() | nil
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
    if not reply.direct_message_only or reply.context.update.message.chat.type == "private" do
      {:cont, reply}
    else
      {:halt, reply}
    end
  end

  defp send_reply({:halt, %__MODULE__{}}), do: :ok

  defp send_reply({:cont, %__MODULE__{context: context, text: text} = reply}) do
    case ExGram.send_message(context.update.message.chat.id, text, send_options(reply)) do
      {:ok, %Message{message_id: id} = message} ->
        JokerCynic.Events.save_sent_message(id, message)
        if reply.on_sent, do: reply.on_sent.(message)
        :ok

      {:error, error} ->
        Logger.error("Error sending message: #{error.message}")
    end
  end

  defp send_options(reply) do
    []
    |> add_bot()
    |> maybe_add_markdown(reply)
    |> maybe_add_reply_to(reply)
  end

  defp add_bot(options), do: [{:bot, JokerCynicBot.bot()} | options]

  defp maybe_add_markdown(options, %__MODULE__{markdown: true}), do: [{:parse_mode, "MarkdownV2"} | options]
  defp maybe_add_markdown(options, _reply), do: options

  defp maybe_add_reply_to(options, reply) do
    if reply.context.update.message.chat.type == "private" or not is_nil(reply.as_reply?) do
      options
    else
      message = reply.context.update.message
      reply_to = %ExGram.Model.ReplyParameters{message_id: message.message_id, chat_id: message.chat.id}
      [{:reply_parameters, reply_to} | options]
    end
  end
end
