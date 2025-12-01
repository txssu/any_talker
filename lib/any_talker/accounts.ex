defmodule AnyTalker.Accounts do
  @moduledoc false
  import Ecto.Query

  alias AnyTalker.Accounts.ChatMember
  alias AnyTalker.Accounts.Subscription
  alias AnyTalker.Accounts.User
  alias AnyTalker.Accounts.UserToken
  alias AnyTalker.Events.Message
  alias AnyTalker.Repo
  alias AnyTalker.Settings.ChatConfig

  def get_user(id) do
    Repo.get(User, id)
  end

  def upsert_user(attrs, keys) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert(on_conflict: {:replace, keys}, conflict_target: [:id])
  end

  def update_user(user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  def change_user(user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  def create_token(user) do
    {token, user_token} = UserToken.build_token(user)
    Repo.insert!(user_token)
    token
  end

  def get_user_by_token(token) do
    {:ok, query} = UserToken.verify_token_query(token)
    Repo.one(query)
  end

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

  def list_user_chats(user_id) do
    query =
      from cm in ChatMember,
        where: cm.user_id == ^user_id,
        left_join: cc in ChatConfig,
        on: cc.id == cm.chat_id,
        select: cc

    Repo.all(query)
  end

  def list_all_chats do
    ChatConfig
    |> order_by(:id)
    |> Repo.all()
  end

  def list_chat_members(chat_id) do
    query =
      from cm in ChatMember,
        where: cm.chat_id == ^chat_id,
        join: u in User,
        on: u.id == cm.user_id,
        select: u,
        order_by: u.id

    Repo.all(query)
  end

  def list_users do
    User
    |> order_by(:id)
    |> Repo.all()
  end

  def owner?(%User{id: user_id}) do
    AnyTalkerBot.Config.owner_id() == user_id
  end

  def chat_member?(user_id, chat_id) do
    query =
      from cm in ChatMember,
        where: cm.user_id == ^user_id and cm.chat_id == ^chat_id

    Repo.exists?(query)
  end

  def display_name(nil), do: nil

  def display_name(%User{} = user) do
    user.custom_name || user.first_name
  end

  def preload_current_subscription(%User{current_subscription: %Subscription{}} = user), do: user
  def preload_current_subscription(%User{current_subscription: nil} = user), do: user

  def preload_current_subscription(%User{} = user) do
    %{user | current_subscription: get_current_subscription(user)}
  end

  def get_current_subscription(%User{id: user_id}) do
    now = DateTime.utc_now()

    query =
      from sub in Subscription,
        where: ^user_id == sub.user_id and (is_nil(sub.expires_at) or sub.expires_at > ^now)

    Repo.one(query)
  end

  def activate_pro_subscription(%User{} = user) do
    expires_at = DateTime.add(DateTime.utc_now(), 30, :day)

    Repo.insert(%Subscription{user_id: user.id, plan: :pro, expires_at: expires_at})
  end

  def activate_pro_subscription_for_days(%User{} = user, days) when is_integer(days) and days > 0 do
    current_subscription = get_current_subscription(user)

    case current_subscription do
      %Subscription{expires_at: nil} = sub ->
        {:ok, sub}

      %Subscription{expires_at: current_expires_at} = sub ->
        new_expires_at = DateTime.add(current_expires_at, days, :day)

        sub
        |> Ecto.Changeset.change(expires_at: new_expires_at)
        |> Repo.update()

      nil ->
        expires_at = DateTime.add(DateTime.utc_now(), days, :day)
        Repo.insert(%Subscription{user_id: user.id, plan: :pro, expires_at: expires_at})
    end
  end

  @doc """
  Returns list of users ordered by last message date (oldest first).

  Users who never sent messages appear first.

  ## Examples

      iex> inactive_users(50)
      [%{user: %User{}, last_message_date: nil}, ...]

  """
  def inactive_users(limit \\ 50) do
    subquery =
      from m in Message,
        group_by: m.from_id,
        select: %{
          user_id: m.from_id,
          last_message_date: max(m.sent_date)
        }

    query =
      from(u in User,
        left_join: lm in subquery(subquery),
        on: u.id == lm.user_id,
        order_by: [asc_nulls_first: lm.last_message_date],
        limit: ^limit,
        select: %{user: u, last_message_date: lm.last_message_date}
      )

    Repo.all(query)
  end

  @doc """
  Returns list of inactive users for specific chat ordered by last message date (oldest first).

  Users who never sent messages in this chat appear first.

  ## Examples

      iex> inactive_users_by_chat(50, -1001234567890)
      [%{user: %User{}, last_message_date: nil}, ...]

  """
  def inactive_users_by_chat(limit \\ 50, chat_id) do
    subquery =
      from m in Message,
        where: m.chat_id == ^chat_id,
        group_by: m.from_id,
        select: %{
          user_id: m.from_id,
          last_message_date: max(m.sent_date)
        }

    query =
      from cm in ChatMember,
        where: cm.chat_id == ^chat_id,
        join: u in User,
        on: u.id == cm.user_id,
        left_join: lm in subquery(subquery),
        on: u.id == lm.user_id,
        order_by: [asc_nulls_first: lm.last_message_date],
        limit: ^limit,
        select: %{user: u, last_message_date: lm.last_message_date}

    Repo.all(query)
  end
end
