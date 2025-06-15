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
  def mount(%{"id" => id}, _session, socket) do
    profile_user = Accounts.get_user(id)

    {:ok,
     socket
     |> assign(profile_user: profile_user, back: ~p"/webapp/users")
     |> assign_profile_form()}
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(profile_user: socket.assigns.current_user, back: ~p"/webapp")
     |> assign_profile_form()}
  end

  @impl Phoenix.LiveView
  def handle_event("back", _params, socket) do
    {:noreply, push_navigate(socket, to: socket.assigns.back)}
  end

  @impl Phoenix.LiveView
  def handle_event("save", %{"user" => attrs}, socket) do
    user = socket.assigns.profile_user

    case Accounts.update_user(user, attrs) do
      {:ok, new_user} ->
        {:noreply,
         socket
         |> assign(profile_user: new_user)
         |> assign_profile_form()}

      {:error, _changeset} ->
        {:noreply, assign_profile_form(socket)}
    end
  end

  defp assign_profile_form(socket) do
    form =
      socket.assigns.profile_user
      |> Accounts.change_user()
      |> to_form()

    assign(socket, form: form)
  end
end
