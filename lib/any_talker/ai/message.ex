defmodule AnyTalker.AI.Message do
  @moduledoc """
  Facade module for AI message handling.

  This module provides a unified interface for working with different types of AI messages
  (Input, Output, FunctionToolCall, FunctionToolCallOutput) and delegates to the appropriate
  message type modules.

  ## Usage

      # Create an input message (user or system)
      message = Message.new("msg_1", :user, "Hello", ~U[2024-01-01 00:00:00Z])

      # Create an output message (assistant)
      response = Message.new("msg_2", :assistant, "Hi there", ~U[2024-01-01 00:00:00Z])

      # Format a list of messages for API
      formatted = Message.format_list([message, response])
  """

  alias AnyTalker.AI.Message.FunctionToolCall
  alias AnyTalker.AI.Message.FunctionToolCallOutput
  alias AnyTalker.AI.Message.Input
  alias AnyTalker.AI.Message.Output

  @doc """
  Creates a new message of the appropriate type based on the role.

  For `:user`, `:system`, or `:developer` roles, creates an Input message.
  For `:assistant` role, creates an Output message.

  ## Examples

      Message.new("msg_1", :user, "Hello", ~U[2024-01-01 00:00:00Z])
      #=> %Input{...}

      Message.new("msg_2", :assistant, "Hi", ~U[2024-01-01 00:00:00Z])
      #=> %Output{...}

      Message.new("msg_3", :user, "Check this", ~U[2024-01-01 00:00:00Z],
        username: "john",
        image_url: "https://example.com/image.jpg"
      )
      #=> %Input{...}
  """
  def new(message_id, role, text, sent_at, options \\ [])

  def new(message_id, :assistant, text, sent_at, options) do
    Output.new(message_id, text, sent_at, options)
  end

  def new(message_id, role, text, sent_at, options) when role in [:user, :system, :developer] do
    Input.new(message_id, role, text, sent_at, options)
  end

  @doc """
  Formats a list of messages for the OpenAI Chat Completions API.

  This function:
  1. For each message with a reply not in the list, prepends the reply message
  2. Formats each message using its format_message/1 callback

  ## Examples

      messages = [
        Message.new("1", :user, "Hello", ~U[2024-01-01 00:00:00Z]),
        Message.new("2", :assistant, "Hi", ~U[2024-01-01 00:01:00Z])
      ]

      Message.format_list(messages)
      #=> [
      #     %{role: :user, content: "..."},
      #     %{role: :assistant, content: "..."}
      #   ]
  """
  def format_list(messages) when is_list(messages) do
    messages
    |> Enum.flat_map(&format_with_reply(&1, get_message_ids(messages)))
    |> Enum.reverse()
  end

  defp get_message_ids(messages) do
    Enum.map(messages, &message_id/1)
  end

  defp message_id(%Input{message_id: id}), do: id
  defp message_id(%Output{message_id: id}), do: id
  defp message_id(%FunctionToolCall{}), do: nil
  defp message_id(%FunctionToolCallOutput{}), do: nil

  defp format_with_reply(%Input{} = message, messages_ids) do
    []
    |> maybe_append_reply(message.reply, messages_ids)
    |> append_formatted(message)
  end

  defp format_with_reply(%Output{} = message, messages_ids) do
    []
    |> maybe_append_reply(message.reply, messages_ids)
    |> append_formatted(message)
  end

  defp format_with_reply(message, _messages_ids) do
    [format_message(message)]
  end

  defp maybe_append_reply(result, nil, _messages_ids), do: result

  defp maybe_append_reply(result, reply, messages_ids) do
    reply_id = message_id(reply)

    if reply_id && reply_id not in messages_ids do
      formatted_reply = format_message(reply)
      [formatted_reply | result]
    else
      result
    end
  end

  defp append_formatted(result, message) do
    [format_message(message) | result]
  end

  defp format_message(%Input{} = message), do: Input.format_message(message)
  defp format_message(%Output{} = message), do: Output.format_message(message)
  defp format_message(%FunctionToolCall{} = message), do: FunctionToolCall.format_message(message)
  defp format_message(%FunctionToolCallOutput{} = message), do: FunctionToolCallOutput.format_message(message)
end
