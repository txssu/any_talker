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
  Creates and sets a callback query action with the given callback_query_id and options.

  This is a convenience function that creates a `Reply.CallbackQuery` and sets it as the action.

  ## Options

  - `:text` - Text of the notification. If not specified, nothing will be shown to the user
  - `:show_alert` - If `true`, an alert will be shown by the client instead of a notification
  - `:url` - URL that will be opened by the user's client
  - `:cache_time` - The maximum amount of time in seconds that the result may be cached client-side

  ## Examples

      reply
      |> Reply.answer_callback_query(callback_query_id)

      reply
      |> Reply.answer_callback_query(callback_query_id, text: "Done!", show_alert: true)
  """
  def answer_callback_query(%__MODULE__{} = reply, callback_query_id, opts \\ []) when is_binary(callback_query_id) do
    callback_query =
      callback_query_id
      |> AnyTalkerBot.Reply.CallbackQuery.new()
      |> struct(opts)

    put_action(reply, callback_query)
  end

  @doc """
  Creates and sets an invoice action with the given parameters and options.

  This is a convenience function that creates a `Reply.Invoice` and sets it as the action.

  ## Options

  - `:for_dm` - Whether to send the invoice to the user's DM (default: `false`)
  - `:provider_token` - Payment provider token (required for payments)
  - `:max_tip_amount` - The maximum accepted amount for tips
  - `:suggested_tip_amounts` - A list of suggested amounts of tips
  - `:start_parameter` - Unique deep-linking parameter
  - `:provider_data` - JSON-serialized data about the invoice
  - `:photo_url` - URL of the product photo
  - `:photo_size` - Photo size in bytes
  - `:photo_width` - Photo width
  - `:photo_height` - Photo height
  - `:need_name` - Pass `true` if you require the user's full name
  - `:need_phone_number` - Pass `true` if you require the user's phone number
  - `:need_email` - Pass `true` if you require the user's email address
  - `:need_shipping_address` - Pass `true` if you require the user's shipping address
  - `:send_phone_number_to_provider` - Pass `true` if the user's phone number should be sent to provider
  - `:send_email_to_provider` - Pass `true` if the user's email address should be sent to provider
  - `:is_flexible` - Pass `true` if the final price depends on the shipping method
  - `:disable_notification` - Sends the message silently
  - `:protect_content` - Protects the contents of the sent message from forwarding and saving
  - `:reply_parameters` - Description of the message to reply to
  - `:reply_markup` - Inline keyboard

  ## Examples

      reply
      |> Reply.send_invoice("Product", "Description", "payload", "USD", [price], provider_token: token)

      reply
      |> Reply.send_invoice("Product", "Description", "payload", "RUB", [price],
        provider_token: token,
        for_dm: true,
        need_email: true,
        photo_url: "https://example.com/photo.jpg"
      )
  """
  def send_invoice(%__MODULE__{} = reply, title, description, payload, currency, prices, opts \\ [])
      when is_binary(title) and is_binary(description) and is_binary(payload) and is_binary(currency) and
             is_list(prices) do
    invoice =
      title
      |> AnyTalkerBot.Reply.Invoice.new(description, payload, currency, prices)
      |> struct(opts)

    put_action(reply, invoice)
  end

  @doc """
  Creates and sets a pre-checkout query action with the given pre_checkout_query_id, ok status and options.

  This is a convenience function that creates a `Reply.PreCheckoutQuery` and sets it as the action.

  ## Options

  - `:error_message` - Error message in human readable form (required if `ok` is `false`)

  ## Examples

      reply
      |> Reply.answer_pre_checkout_query(pre_checkout_query_id, true)

      reply
      |> Reply.answer_pre_checkout_query(pre_checkout_query_id, false, error_message: "Already subscribed")
  """
  def answer_pre_checkout_query(%__MODULE__{} = reply, pre_checkout_query_id, ok, opts \\ [])
      when is_binary(pre_checkout_query_id) and is_boolean(ok) do
    pre_checkout_query =
      pre_checkout_query_id
      |> AnyTalkerBot.Reply.PreCheckoutQuery.new(ok)
      |> struct(opts)

    put_action(reply, pre_checkout_query)
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
