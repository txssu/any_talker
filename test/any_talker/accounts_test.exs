defmodule AnyTalker.AccountsTest do
  use AnyTalker.DataCase, async: true

  import AnyTalker.AccountsFixtures

  alias AnyTalker.Accounts

  describe "toggle_admin/1" do
    test "sets admin to true when it is false" do
      user = user_fixture()
      assert user.admin == false

      {:ok, updated} = Accounts.toggle_admin(user)
      assert updated.admin == true
    end

    test "sets admin to false when it is true" do
      user = admin_user_fixture()
      assert user.admin == true

      {:ok, updated} = Accounts.toggle_admin(user)
      assert updated.admin == false
    end

    test "persists the change to the database" do
      user = user_fixture()
      {:ok, _updated} = Accounts.toggle_admin(user)
      assert Accounts.get_user(user.id).admin == true
    end
  end

  describe "set_pro_subscription/2" do
    test "creates a new PRO subscription with no expiration" do
      user = user_fixture()

      {:ok, sub} = Accounts.set_pro_subscription(user)

      assert sub.plan == :pro
      assert sub.expires_at == nil
      assert sub.user_id == user.id
    end

    test "creates a new PRO subscription with an expiration date" do
      user = user_fixture()

      expires_at =
        DateTime.utc_now()
        |> DateTime.add(30, :day)
        |> DateTime.truncate(:microsecond)

      {:ok, sub} = Accounts.set_pro_subscription(user, expires_at)

      assert sub.plan == :pro
      assert sub.expires_at == expires_at
    end

    test "updates expires_at on an existing active subscription" do
      user = user_fixture()
      {:ok, original} = Accounts.set_pro_subscription(user)

      new_expires_at =
        DateTime.utc_now()
        |> DateTime.add(60, :day)
        |> DateTime.truncate(:microsecond)

      {:ok, updated} = Accounts.set_pro_subscription(user, new_expires_at)

      assert updated.id == original.id
      assert updated.expires_at == new_expires_at
    end

    test "updates expires_at on an already-dated subscription" do
      user = user_fixture()

      first_expires_at =
        DateTime.utc_now()
        |> DateTime.add(10, :day)
        |> DateTime.truncate(:microsecond)

      {:ok, original} = Accounts.set_pro_subscription(user, first_expires_at)

      new_expires_at =
        DateTime.utc_now()
        |> DateTime.add(30, :day)
        |> DateTime.truncate(:microsecond)

      {:ok, updated} = Accounts.set_pro_subscription(user, new_expires_at)

      assert updated.id == original.id
      assert updated.expires_at == new_expires_at
      assert Accounts.get_current_subscription(user).expires_at == new_expires_at
    end
  end

  describe "revoke_subscription/1" do
    test "deletes the active subscription" do
      user = user_fixture()
      {:ok, _sub} = Accounts.set_pro_subscription(user)

      {:ok, _deleted} = Accounts.revoke_subscription(user)

      assert Accounts.get_current_subscription(user) == nil
    end

    test "returns {:ok, nil} when user has no subscription" do
      user = user_fixture()

      assert {:ok, nil} = Accounts.revoke_subscription(user)
    end
  end
end
