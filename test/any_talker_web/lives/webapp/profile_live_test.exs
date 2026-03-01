defmodule AnyTalkerWeb.WebApp.ProfileLiveTest do
  use AnyTalkerWeb.ConnCase, async: true

  import AnyTalker.AccountsFixtures
  import Phoenix.LiveViewTest

  alias AnyTalker.Accounts

  defp log_in(conn, user) do
    token = Accounts.create_token(user)
    Plug.Test.init_test_session(conn, %{user_token: token})
  end

  describe "PRO subscription section" do
    test "is visible to admin viewing another user's profile", %{conn: conn} do
      admin = admin_user_fixture()
      target = user_fixture()
      conn = log_in(conn, admin)

      {:ok, _view, html} = live(conn, ~p"/webapp/profile/#{target.id}")

      assert html =~ "PRO подписка"
    end

    test "is not visible to non-admin", %{conn: conn} do
      # Use a fixed large ID to avoid collision with owner_id: 1 in test config
      viewer = user_fixture(%{id: 9_999_998})
      target = user_fixture(%{id: 9_999_999})
      conn = log_in(conn, viewer)

      # Non-admin is redirected from /profile/:id (admin-only route)
      assert {:error, {:redirect, %{to: "/webapp"}}} =
               live(conn, ~p"/webapp/profile/#{target.id}")
    end

    test "shows 'Нет подписки' when user has no subscription", %{conn: conn} do
      admin = admin_user_fixture()
      target = user_fixture()
      conn = log_in(conn, admin)

      {:ok, _view, html} = live(conn, ~p"/webapp/profile/#{target.id}")

      assert html =~ "Нет подписки"
    end

    test "shows expiration date when subscription has one", %{conn: conn} do
      admin = admin_user_fixture()
      target = user_fixture()
      expires_at = ~U[2030-06-15 23:59:59.000000Z]
      {:ok, _sub} = Accounts.set_pro_subscription(target, expires_at)
      conn = log_in(conn, admin)

      {:ok, _view, html} = live(conn, ~p"/webapp/profile/#{target.id}")

      assert html =~ "15.06.2030"
    end

    test "shows 'бессрочно' when subscription has no expiration", %{conn: conn} do
      admin = admin_user_fixture()
      target = user_fixture()
      {:ok, _sub} = Accounts.set_pro_subscription(target)
      conn = log_in(conn, admin)

      {:ok, _view, html} = live(conn, ~p"/webapp/profile/#{target.id}")

      assert html =~ "бессрочно"
    end

    test "grant PRO with a specific date", %{conn: conn} do
      admin = admin_user_fixture()
      target = user_fixture()
      conn = log_in(conn, admin)

      {:ok, view, _html} = live(conn, ~p"/webapp/profile/#{target.id}")

      html =
        view
        |> form("#pro-subscription-form", %{expires_at: "2030-01-01"})
        |> render_submit()

      assert html =~ "01.01.2030"
      assert Accounts.get_current_subscription(target)
    end

    test "grant PRO indefinitely", %{conn: conn} do
      admin = admin_user_fixture()
      target = user_fixture()
      conn = log_in(conn, admin)

      {:ok, view, _html} = live(conn, ~p"/webapp/profile/#{target.id}")

      html = render_click(view, "grant_pro_indefinitely")

      assert html =~ "бессрочно"
      assert Accounts.get_current_subscription(target).expires_at == nil
    end

    test "revoke PRO removes subscription", %{conn: conn} do
      admin = admin_user_fixture()
      target = user_fixture()
      {:ok, _sub} = Accounts.set_pro_subscription(target)
      conn = log_in(conn, admin)

      {:ok, view, _html} = live(conn, ~p"/webapp/profile/#{target.id}")

      html = render_click(view, "revoke_pro")

      assert html =~ "Нет подписки"
      assert Accounts.get_current_subscription(target) == nil
    end

    test "revoke PRO button not shown when user has no subscription", %{conn: conn} do
      admin = admin_user_fixture()
      target = user_fixture()
      conn = log_in(conn, admin)

      {:ok, _view, html} = live(conn, ~p"/webapp/profile/#{target.id}")

      refute html =~ "Отозвать PRO"
    end
  end
end
