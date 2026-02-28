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
end
