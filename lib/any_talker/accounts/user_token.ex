defmodule AnyTalker.Accounts.UserToken do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Query

  alias AnyTalker.Accounts.User

  @rand_size 32

  @type t :: %__MODULE__{}

  @session_validity_in_days 60

  schema "users_tokens" do
    field :token, :binary
    field :context, :string
    field :sent_to, :string
    belongs_to :user, User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def build_token(user) do
    token = :crypto.strong_rand_bytes(@rand_size)
    {token, %__MODULE__{token: token, user_id: user.id}}
  end

  def verify_token_query(token) do
    query =
      from token in by_token(token),
        join: user in assoc(token, :user),
        where: token.inserted_at > ago(@session_validity_in_days, "day"),
        select: user

    {:ok, query}
  end

  def by_token(token) do
    from __MODULE__, where: [token: ^token]
  end
end
