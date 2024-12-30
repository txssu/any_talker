defmodule JokerCynic.Accounts do
  @moduledoc false
  alias JokerCynic.Accounts.User
  alias JokerCynic.Accounts.UserToken
  alias JokerCynic.Repo

  @spec upsert_user(map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def upsert_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert(on_conflict: {:replace, ~w[username first_name last_name]a}, conflict_target: [:id])
  end

  def update_user(user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @spec create_token(User.t()) :: String.t()
  def create_token(user) do
    {token, user_token} = UserToken.build_token(user)
    Repo.insert!(user_token)
    token
  end

  @spec get_user_by_token(String.t()) :: User.t() | nil
  def get_user_by_token(token) do
    {:ok, query} = UserToken.verify_token_query(token)
    Repo.one(query)
  end
end
