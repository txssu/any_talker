defmodule AnyTalkerBot.Reply do
  @moduledoc false

  import AnyTalkerBot.MarkdownUtils

  alias ExGram.Cnt

  require Logger

  defstruct text: nil,
            halt: false,
            mode: :html,
            on_sent: nil,
            as_reply?: false,
            for_dm: false,
            message: nil,
            context: nil

  def new(%Cnt{} = context, message) do
    %__MODULE__{message: message, context: context}
  end

  def execute(%__MODULE__{} = reply) do
    reply
    |> check_halt()
    |> check_for_dm()
    |> send_reply()
  end

  defp check_halt(%__MODULE__{halt: true} = reply), do: {:halt, reply}
  defp check_halt(%__MODULE__{halt: false} = reply), do: {:cont, reply}

  defp check_for_dm({:halt, reply}), do: {:halt, reply}

  defp check_for_dm({:cont, %__MODULE__{for_dm: true} = reply}) do
    if dm?(reply) do
      # Already in DM, proceed normally
      {:cont, reply}
    else
      # In group chat, send content to DM and notify in group
      send_to_dm(reply)
    end
  end

  defp check_for_dm({:cont, reply}), do: {:cont, reply}

  defp send_to_dm(reply) do
    user_id = reply.context.update.message.from.id

    case do_send_message(user_id, reply.text, reply) do
      :ok -> {:cont, %{reply | text: dm_success_message(), mode: :html}}
      :error -> {:cont, %{reply | text: dm_error_message(), mode: :html}}
    end
  end

  defp dm?(%__MODULE__{context: context}) do
    context.update.message.chat.type == "private"
  end

  defp dm_success_message do
    "Ответ отправлен в личные сообщения."
  end

  defp dm_error_message do
    ~i"Не удалось отправить сообщение в личные сообщения\. Пожалуйста, разблокируйте бота и начните с ним диалог командой /start\."
  end

  defp send_reply({:halt, %__MODULE__{}}), do: :ok

  defp send_reply({:cont, %__MODULE__{context: context, text: text} = reply}) do
    chat_id = context.update.message.chat.id
    do_send_message(chat_id, text, reply)
    :ok
  end

  defp do_send_message(chat_id, text, reply) do
    case ExGram.send_message(chat_id, text, send_options(reply)) do
      {:ok, message} ->
        AnyTalker.Events.save_new_message(message)
        if reply.on_sent, do: reply.on_sent.(message)
        :ok

      {:error, error} ->
        Logger.error("Error sending message: #{inspect(error)}")
        :error
    end
  end

  defp send_options(reply) do
    []
    |> add_bot()
    |> maybe_add_markdown(reply)
    |> maybe_add_reply_to(reply)
  end

  defp add_bot(options), do: [{:bot, AnyTalkerBot.bot()} | options]

  defp maybe_add_markdown(options, %__MODULE__{mode: :html}), do: [{:parse_mode, "HTML"} | options]
  defp maybe_add_markdown(options, _reply), do: options

  defp maybe_add_reply_to(options, reply) do
    if reply.context.update.message.chat.type != "private" or reply.as_reply? do
      message = reply.context.update.message
      reply_to = %ExGram.Model.ReplyParameters{message_id: message.message_id, chat_id: message.chat.id}
      [{:reply_parameters, reply_to} | options]
    else
      options
    end
  end
end
