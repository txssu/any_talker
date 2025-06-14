defmodule AnyTalkerWeb.WebApp.ProfileLive do
  @moduledoc false
  use AnyTalkerWeb, :live_view

  import AnyTalkerWeb.TelegramComponents

  alias AnyTalker.Accounts

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div id="back-init" phx-hook="TelegramBack" data-state="on"></div>
    <.section class="pt-[30px] pb-[15px]">
      <h1 class="mt-[15px] text-center text-xl font-bold">Настройки профиля</h1>
    </.section>

    <.section class="mt-5">
      <:header>Профиль</:header>
      <.form for={@form} phx-change="save">
        <div class="space-y-3">
          <.tg_input label="Ник" field={@form[:custom_name]} />
        </div>
      </.form>
    </.section>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, assign_form(socket)}
  end

  @impl Phoenix.LiveView
  def handle_event("back", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/webapp")}
  end

  @impl Phoenix.LiveView
  def handle_event("save", %{"user" => attrs}, socket) do
    user = socket.assigns.current_user

    case Accounts.update_user(user, attrs) do
      {:ok, new_user} ->
        {:noreply, assign_form(assign(socket, current_user: new_user))}

      {:error, _changeset} ->
        {:noreply, assign_form(socket)}
    end
  end

  defp assign_form(socket) do
    form =
      socket.assigns.current_user
      |> Accounts.change_user()
      |> to_form()

    assign(socket, form: form)
  end
end
