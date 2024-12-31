defmodule JokerCynic.Accounts do
  @moduledoc false
  import Ecto.Query

  alias JokerCynic.Accounts.ChatMember
  alias JokerCynic.Accounts.User
  alias JokerCynic.Accounts.UserToken
  alias JokerCynic.Repo

  @spec upsert_user(map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def upsert_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert(on_conflict: {:replace, ~w[username first_name last_name]a}, conflict_target: [:id])
  end

  @spec update_user(User.t(), map()) :: {:ok, User.t()}
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

  @spec add_chat_member(integer(), integer()) :: {:ok, ChatMember.t()}
  def add_chat_member(user_id, chat_id) do
    %ChatMember{user_id: user_id, chat_id: chat_id}
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.unique_constraint(:user_id, name: "chats_members_user_id_chat_id_index")
    |> Repo.insert()
  end

  @spec list_user_chats(integer()) :: [ChatMember.t()]
  def list_user_chats(user_id) do
    query =
      from cm in ChatMember,
        where: cm.user_id == ^user_id

    Repo.all(query)
  end
end
