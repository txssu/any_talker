defmodule AnyTalkerBot.LoadDataMiddleware do
  @moduledoc false
  use ExGram.Middleware

  alias AnyTalker.Accounts
  alias AnyTalker.Settings

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

    is_group = message_chat.id != message_user.id

    if is_group do
      Accounts.add_chat_member(message_user.id, message_chat.id, message_chat.title)
    end

    chat = Settings.get_chat_config(message_chat.id)

    context
    |> add_extra(:user, maybe_user)
    |> add_extra(:chat, chat)
    |> add_extra(:is_group, is_group)
  end

  def call(context, _options) do
    context
    |> add_extra(:user, nil)
    |> add_extra(:chat, nil)
  end
end
