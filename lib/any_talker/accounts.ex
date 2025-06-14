defmodule AnyTalker.Accounts do
  @moduledoc false
  import Ecto.Query

  alias AnyTalker.Accounts.ChatMember
  alias AnyTalker.Accounts.User
  alias AnyTalker.Accounts.UserToken
  alias AnyTalker.Repo
  alias AnyTalker.Settings.ChatConfig

  @spec get_user(integer()) :: User.t() | nil
  def get_user(id) do
    Repo.get(User, id)
  end

  @spec upsert_user(map(), [atom()]) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def upsert_user(attrs, keys) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert(on_conflict: {:replace, keys}, conflict_target: [:id])
  end

  @spec update_user(User.t(), map()) :: {:ok, User.t()}
  def update_user(user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @spec change_user(User.t(), map()) :: Ecto.Changeset.t()
  def change_user(user, attrs \\ %{}) do
    User.changeset(user, attrs)
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

  @spec add_chat_member(integer(), integer(), String.t()) :: {:ok, any()} | {:error, any()} | Ecto.Multi.failure()
  def add_chat_member(user_id, chat_id, chat_title) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:chat_member, fn _schema ->
      %ChatMember{user_id: user_id, chat_id: chat_id}
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.unique_constraint(:user_id, name: "chats_members_chat_id_user_id_index")
    end)
    |> Ecto.Multi.run(:chat_config, fn _repo, _data ->
      AnyTalker.Settings.upsert_chat_config(chat_id, chat_title)
    end)
    |> Repo.transaction()
  end

  @spec list_user_chats(integer()) :: [ChatConfig.t()]
  def list_user_chats(user_id) do
    query =
      from cm in ChatMember,
        where: cm.user_id == ^user_id,
        left_join: cc in ChatConfig,
        on: cc.id == cm.chat_id,
        select: cc

    Repo.all(query)
  end

  @spec owner?(User.t()) :: boolean()
  def owner?(%User{id: user_id}) do
    Application.get_env(:any_talker, :owner_id) == user_id
  end

  @spec display_name(User.t() | nil) :: String.t() | nil
  def display_name(nil), do: nil

  def display_name(%User{} = user) do
    user.custom_name || user.first_name
  end
end
