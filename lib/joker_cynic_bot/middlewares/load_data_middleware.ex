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
    {:ok, user} =
      message_user
      |> Map.from_struct()
      |> Map.take(~w[id username first_name last_name]a)
      |> Accounts.upsert_user()

    chat = Settings.get_chat_config(message_chat.id)

    context
    |> add_extra(:user, user)
    |> add_extra(:chat, chat)
  end

  def call(context, _options) do
    context
  end
end
