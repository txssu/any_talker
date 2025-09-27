defmodule AnyTalker.Accounts.Subscription do
  @moduledoc """
  User subscription representation.

  ## Fields

  | Field Name | Type | Description |
  |------------|------|-------------|
  | user_id | integer | Reference to the user |
  | plan | enum | Subscription plan |
  | expires_at | utc_datetime_usec | Subscription expiration date |
  """
  use Ecto.Schema

  alias AnyTalker.Accounts.User

  @type t :: %__MODULE__{}

  schema "subscriptions" do
    belongs_to :user, User
    field :plan, Ecto.Enum, values: [:pro]
    field :expires_at, :utc_datetime_usec

    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  @doc """
  Checks if subscription is currently active.
  """
  def active?(%__MODULE__{expires_at: nil}), do: true

  def active?(%__MODULE__{expires_at: expires_at}) do
    DateTime.after?(expires_at, DateTime.utc_now())
  end

  def active?(_subscription), do: false

  @doc """
  Checks if subscription is PRO plan.
  """
  def pro?(%__MODULE__{plan: :pro}), do: true
  def pro?(_subscription), do: false

  @doc """
  Checks if subscription is active PRO plan.
  """
  def active_pro?(subscription) do
    active?(subscription) && pro?(subscription)
  end
end
