defmodule JokerCynicBot.LoadDataMiddleware do
  @moduledoc false
  use ExGram.Middleware

  alias JokerCynic.Accounts
  alias JokerCynic.Settings

  @spec call(ExGram.Cnt.t(), any()) :: ExGram.Cnt.t()
  def call(
        %ExGram.Cnt{
          update: %ExGram.Model.Update{message: %ExGram.Model.Message{chat: message_chat, from: message_user}}
        } = context,
        _options
      ) do
    upsert_result =
      message_user
      |> Map.from_struct()
      |> Accounts.upsert_user(~w[username first_name last_name]a)

    maybe_user =
      case upsert_result do
        {:ok, user} -> user
        _err -> nil
      end

    chat = Settings.get_chat_config(message_chat.id)

    context
    |> add_extra(:user, maybe_user)
    |> add_extra(:chat, chat)
  end

  def call(context, _options) do
    context
    |> add_extra(:user, nil)
    |> add_extra(:chat, nil)
  end
end
