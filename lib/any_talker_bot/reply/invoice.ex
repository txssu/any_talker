defmodule AnyTalkerBot.Reply.Invoice do
  @moduledoc """
  An invoice action for Reply that sends payment invoices in Telegram.

  This module handles sending payment invoices with various options.

  ## Fields

  - `title` - Product name, 1-32 characters
  - `description` - Product description, 1-255 characters
  - `payload` - Bot-defined invoice payload, 1-128 bytes
  - `currency` - Three-letter ISO 4217 currency code
  - `prices` - List of price portions (ExGram.Model.LabeledPrice)
  - `for_dm` - Whether to send the invoice to the user's DM (default: `false`)
  - `provider_token` - Payment provider token
  - `max_tip_amount` - The maximum accepted amount for tips in the smallest units of the currency
  - `suggested_tip_amounts` - A list of suggested amounts of tips in the smallest units of the currency
  - `start_parameter` - Unique deep-linking parameter
  - `provider_data` - JSON-serialized data about the invoice
  - `photo_url` - URL of the product photo for the invoice
  - `photo_size` - Photo size in bytes
  - `photo_width` - Photo width
  - `photo_height` - Photo height
  - `need_name` - Pass `true` if you require the user's full name to complete the order
  - `need_phone_number` - Pass `true` if you require the user's phone number to complete the order
  - `need_email` - Pass `true` if you require the user's email address to complete the order
  - `need_shipping_address` - Pass `true` if you require the user's shipping address to complete the order
  - `send_phone_number_to_provider` - Pass `true` if the user's phone number should be sent to provider
  - `send_email_to_provider` - Pass `true` if the user's email address should be sent to provider
  - `is_flexible` - Pass `true` if the final price depends on the shipping method
  - `disable_notification` - Sends the message silently
  - `protect_content` - Protects the contents of the sent message from forwarding and saving
  - `reply_parameters` - Description of the message to reply to
  - `reply_markup` - Inline keyboard

  ## Example

      Reply.Invoice.new("Product", "Description", "payload", "USD", [price])
  """

  @behaviour AnyTalkerBot.Reply.Action

  alias AnyTalkerBot.Reply
  alias AnyTalkerBot.Reply.Common

  require Logger

  defstruct title: nil,
            description: nil,
            payload: nil,
            currency: nil,
            prices: [],
            for_dm: false,
            provider_token: nil,
            max_tip_amount: nil,
            suggested_tip_amounts: nil,
            start_parameter: nil,
            provider_data: nil,
            photo_url: nil,
            photo_size: nil,
            photo_width: nil,
            photo_height: nil,
            need_name: nil,
            need_phone_number: nil,
            need_email: nil,
            need_shipping_address: nil,
            send_phone_number_to_provider: nil,
            send_email_to_provider: nil,
            is_flexible: nil,
            disable_notification: nil,
            protect_content: nil,
            reply_parameters: nil,
            reply_markup: nil

  @doc """
  Creates a new Invoice with the required fields.

  ## Example

      Reply.Invoice.new("Product", "Description", "payload", "USD", [price])
  """
  def new(title, description, payload, currency, prices)
      when is_binary(title) and is_binary(description) and is_binary(payload) and is_binary(currency) and
             is_list(prices) do
    %__MODULE__{
      title: title,
      description: description,
      payload: payload,
      currency: currency,
      prices: prices
    }
  end

  @impl Reply.Action
  def execute(%Reply{action: %__MODULE__{} = invoice} = reply) do
    invoice
    |> check_for_dm(reply)
    |> do_send(reply)
  end

  defp check_for_dm(%__MODULE__{for_dm: false} = invoice, %Reply{}), do: {:cont, invoice}

  defp check_for_dm(%__MODULE__{for_dm: true} = invoice, %Reply{} = reply) do
    if dm?(reply) do
      {:cont, invoice}
    else
      send_to_dm(invoice, reply)
    end
  end

  defp dm?(%Reply{context: context}) do
    context.update.message.chat.type == "private"
  end

  defp send_to_dm(%__MODULE__{} = invoice, %Reply{} = reply) do
    user_id = reply.context.update.message.from.id

    case send_invoice(invoice, reply, user_id) do
      {:ok, _sent_message} ->
        success_message = %Reply.Message{
          text: Common.dm_success_message(),
          mode: :html
        }

        {:cont, success_message}

      {:error, _reason} ->
        error_message = %Reply.Message{
          text: Common.dm_error_message(),
          mode: :html
        }

        {:cont, error_message}
    end
  end

  defp do_send({:cont, %__MODULE__{} = invoice}, %Reply{} = reply) do
    chat_id = reply.context.update.message.chat.id
    send_invoice(invoice, reply, chat_id)
  end

  defp do_send({:cont, %Reply.Message{} = message}, %Reply{} = reply) do
    chat_id = reply.context.update.message.chat.id

    case ExGram.send_message(chat_id, message.text, send_message_options(message, reply)) do
      {:ok, sent_message} ->
        AnyTalker.Events.save_new_message(sent_message)
        {:ok, sent_message}

      {:error, error} ->
        Logger.error("Error sending DM notification message: #{inspect(error)}")
        {:error, error}
    end
  end

  defp send_invoice(%__MODULE__{} = invoice, %Reply{} = _reply, chat_id) do
    options = build_options(invoice)

    case ExGram.send_invoice(
           chat_id,
           invoice.title,
           invoice.description,
           invoice.payload,
           invoice.currency,
           invoice.prices,
           options
         ) do
      {:ok, sent_message} ->
        {:ok, sent_message}

      {:error, error} ->
        Logger.error("Error sending invoice: #{inspect(error)}")
        {:error, error}
    end
  end

  defp send_message_options(%Reply.Message{} = message, %Reply{} = reply) do
    []
    |> Common.add_bot()
    |> Common.maybe_add_markdown(message.mode)
    |> Common.maybe_add_reply_to(reply, message.as_reply?)
  end

  defp build_options(%__MODULE__{} = invoice) do
    Enum.reject(
      [
        bot: AnyTalkerBot.Dispatcher.bot(),
        provider_token: invoice.provider_token,
        max_tip_amount: invoice.max_tip_amount,
        suggested_tip_amounts: invoice.suggested_tip_amounts,
        start_parameter: invoice.start_parameter,
        provider_data: invoice.provider_data,
        photo_url: invoice.photo_url,
        photo_size: invoice.photo_size,
        photo_width: invoice.photo_width,
        photo_height: invoice.photo_height,
        need_name: invoice.need_name,
        need_phone_number: invoice.need_phone_number,
        need_email: invoice.need_email,
        need_shipping_address: invoice.need_shipping_address,
        send_phone_number_to_provider: invoice.send_phone_number_to_provider,
        send_email_to_provider: invoice.send_email_to_provider,
        is_flexible: invoice.is_flexible,
        disable_notification: invoice.disable_notification,
        protect_content: invoice.protect_content,
        reply_parameters: invoice.reply_parameters,
        reply_markup: invoice.reply_markup
      ],
      fn {_k, v} -> is_nil(v) end
    )
  end
end
