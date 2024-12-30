defmodule JokerCynicBot.LoadDataMiddleware do
  @moduledoc false
  use ExGram.Middleware

  alias JokerCynic.Accounts

  @spec call(ExGram.Cnt.t(), any()) :: ExGram.Cnt.t()
  def call(
        %ExGram.Cnt{update: %ExGram.Model.Update{message: %ExGram.Model.Message{chat: _chat, from: from}}} = context,
        _options
      ) do
    user =
      from
      |> Map.from_struct()
      |> Map.take(~w[id username first_name last_name]a)
      |> Accounts.upsert_user()

    add_extra(context, :user, user)
  end

  def call(context, _options) do
    context
  end
end
