defmodule AnyTalkerBot.Reply do
  @moduledoc """
  An extensible reply system for handling different types of bot actions.

  This module provides a general-purpose reply structure that can work with
  different types of actions through the `Reply.Action` behaviour. Unlike the
  original `Reply` module, `Reply` separates common concerns (context, halt state)
  from action-specific behavior (sending messages, inline callbacks, etc.).

  ## Usage

      reply = Reply.new(context, message)
      reply = Reply.put_action(reply, Reply.Message.new("Hello"))
      Reply.execute(reply)

  ## Fields

  - `action` - The action to execute (implements `Reply.Action` behaviour)
  - `halt` - If true, execution is skipped
  - `message` - The original message that triggered this reply
  - `context` - The ExGram context
  """

  defstruct action: nil,
            halt: false,
            message: nil,
            context: nil

  @doc """
  Creates a new Reply with the given context and message.

  ## Example

      Reply.new(context, message)
  """
  def new(%ExGram.Cnt{} = context, message) do
    %__MODULE__{context: context, message: message}
  end

  @doc """
  Sets the action to be executed.

  ## Example

      reply
      |> Reply.put_action(Reply.Message.new("Hello"))
  """
  def put_action(%__MODULE__{} = reply, action) do
    %{reply | action: action}
  end

  @doc """
  Creates and sets a message action with the given text and options.

  This is a convenience function that creates a `Reply.Message` and sets it as the action.

  ## Options

  - `:mode` - Parse mode (`:html`, `:markdown`, or `nil`)
  - `:as_reply?` - Whether to reply to the original message (default: `false`)
  - `:for_dm` - Whether to send the message to the user's DM (default: `false`)
  - `:on_sent` - Callback function to run after the message is sent

  ## Examples

      reply
      |> Reply.send_message("Hello")

      reply
      |> Reply.send_message("Hello", mode: :html, as_reply?: true)

      reply
      |> Reply.send_message("Hello", for_dm: true, on_sent: fn msg -> IO.inspect(msg) end)
  """
  def send_message(%__MODULE__{} = reply, text, opts \\ []) when is_binary(text) do
    message =
      text
      |> AnyTalkerBot.Reply.Message.new()
      |> struct(opts)

    put_action(reply, message)
  end

  @doc """
  Creates and sets an inline query action with the given query_id, results and options.

  This is a convenience function that creates a `Reply.InlineQuery` and sets it as the action.

  ## Options

  - `:cache_time` - The maximum amount of time in seconds that the result may be cached on the server
  - `:is_personal` - Pass `true` if results may be cached on the server side only for the user that sent the query
  - `:next_offset` - Pass the offset that a client should send in the next query with the same text to receive more results
  - `:button` - A button to be shown above inline query results

  ## Examples

      reply
      |> Reply.answer_inline_query(query_id, [result])

      reply
      |> Reply.answer_inline_query(query_id, [result], cache_time: 300, is_personal: true)
  """
  def answer_inline_query(%__MODULE__{} = reply, query_id, results, opts \\ [])
      when is_binary(query_id) and is_list(results) do
    inline_query =
      query_id
      |> AnyTalkerBot.Reply.InlineQuery.new(results)
      |> struct(opts)

    put_action(reply, inline_query)
  end

  @doc """
  Marks the reply as halted, preventing execution.

  ## Example

      reply
      |> Reply.halt()
  """
  def halt(%__MODULE__{} = reply) do
    %{reply | halt: true}
  end

  @doc """
  Executes the reply action if not halted.

  Returns `:ok` after execution or if halted.

  ## Example

      Reply.execute(reply)
  """
  def execute(%__MODULE__{} = reply) do
    reply
    |> check_halt()
    |> execute_action()
  end

  defp check_halt(%__MODULE__{halt: true} = reply), do: {:halt, reply}
  defp check_halt(%__MODULE__{halt: false} = reply), do: {:cont, reply}

  defp execute_action({:halt, %__MODULE__{}}), do: :ok

  defp execute_action({:cont, %__MODULE__{action: %module{}} = reply}) do
    module.execute(reply)
    :ok
  end
end
