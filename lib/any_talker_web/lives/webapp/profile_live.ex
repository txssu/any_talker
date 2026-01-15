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
      <div class="flex justify-center">
        <img
          src={@profile_user.photo_url || ~p"/user_avatar/#{@profile_user.id}"}
          class="size-20 rounded-full"
          alt="User photo"
        />
      </div>
      <h1 class="mt-[15px] text-center text-xl font-bold">Настройки профиля</h1>
    </.section>

    <.section :if={@profile_user.username} class="mt-5">
      <div class="px-3">
        <a
          href={"https://t.me/#{@profile_user.username}"}
          target="_blank"
          class="flex w-full items-center justify-center rounded-lg bg-blue-600 px-4 py-2 font-medium text-white transition-colors hover:bg-blue-700"
        >
          Открыть
        </a>
      </div>
    </.section>

    <.section class="mt-5">
      <:header>Настройки</:header>
      <.form for={@form} phx-change="validate" phx-submit="save">
        <div class="space-y-3">
          <.tg_input label="Ник" field={@form[:custom_name]} />
          <.tg_input label="Таймзона" field={@form[:timezone]} />
          <div class="px-3 pt-3">
            <button
              type="submit"
              phx-disable-with="Сохранение..."
              class="w-full rounded-lg bg-blue-600 px-4 py-2 font-medium text-white transition-colors hover:bg-blue-700"
            >
              Сохранить
            </button>
          </div>
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
     |> assign(profile_user: profile_user)
     |> assign_profile_form()}
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(profile_user: socket.assigns.current_user)
     |> assign_profile_form()}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"user" => attrs}, socket) do
    user = socket.assigns.profile_user

    changeset =
      user
      |> Accounts.change_user(attrs)
      |> Map.put(:action, :validate)

    form = to_form(changeset)

    {:noreply, assign(socket, form: form)}
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
