defmodule AnyTalker.AccountsFixtures do
  @moduledoc """
  Fixtures for Accounts tests.

  ## Usage

      import AnyTalker.AccountsFixtures

      user = user_fixture()
      admin = admin_user_fixture()
  """

  alias AnyTalker.Accounts
  alias AnyTalker.Accounts.User
  alias AnyTalker.Repo

  def user_fixture(attrs \\ %{}) do
    defaults = %{id: System.unique_integer([:positive, :monotonic]), first_name: "Test"}

    {:ok, user} =
      defaults
      |> Map.merge(attrs)
      |> Accounts.upsert_user(~w[first_name]a)

    user
  end

  def admin_user_fixture(attrs \\ %{}) do
    defaults = %{id: System.unique_integer([:positive, :monotonic]), first_name: "Test", admin: true}

    defaults
    |> Map.merge(attrs)
    |> then(&struct!(User, &1))
    |> Repo.insert!()
  end
end
