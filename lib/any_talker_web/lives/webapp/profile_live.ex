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

    <.section :if={@profile_user.id == @current_user.id or @current_user.admin} class="mt-5">
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

    <.section :if={Accounts.owner?(@current_user)} class="mt-5">
      <:header>Администратор</:header>
      <div class="px-3 pt-3">
        <button
          phx-click="toggle_admin"
          class="bg-zk-surface w-full rounded-lg px-4 py-2 font-medium transition-colors hover:opacity-80"
        >
          {if @profile_user.admin, do: "Снять права администратора", else: "Сделать администратором"}
        </button>
      </div>
    </.section>

    <.section :if={@current_user.admin} class="mt-5">
      <:header>PRO подписка</:header>
      <div class="space-y-3 px-3 pt-3">
        <p class="text-[15px]">
          Статус:
          <span :if={is_nil(@profile_user.current_subscription)} class="text-tg-hint">
            Нет подписки
          </span>
          <span
            :if={
              not is_nil(@profile_user.current_subscription) and
                is_nil(@profile_user.current_subscription.expires_at)
            }
            class="font-medium text-green-500"
          >
            PRO (бессрочно)
          </span>
          <span
            :if={
              not is_nil(@profile_user.current_subscription) and
                not is_nil(@profile_user.current_subscription.expires_at)
            }
            class="font-medium text-green-500"
          >
            PRO до {Calendar.strftime(@profile_user.current_subscription.expires_at, "%d.%m.%Y")}
          </span>
        </p>

        <.form id="pro-subscription-form" for={%{}} phx-submit="grant_pro">
          <div class="space-y-2">
            <input
              type="date"
              name="expires_at"
              required
              class="mx-[3px] block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6"
            />
            <button
              type="submit"
              class="w-full rounded-lg bg-blue-600 px-4 py-2 font-medium text-white transition-colors hover:bg-blue-700"
            >
              Выдать PRO
            </button>
          </div>
        </.form>

        <button
          phx-click="grant_pro_indefinitely"
          class="bg-zk-surface w-full rounded-lg px-4 py-2 font-medium transition-colors hover:opacity-80"
        >
          Выдать PRO бессрочно
        </button>

        <button
          :if={not is_nil(@profile_user.current_subscription)}
          phx-click="revoke_pro"
          class="w-full rounded-lg bg-red-600 px-4 py-2 font-medium text-white transition-colors hover:bg-red-700"
        >
          Отозвать PRO
        </button>
      </div>
    </.section>
    """
  end

  @impl Phoenix.LiveView
  def mount(%{"id" => id}, _session, socket) do
    profile_user =
      id
      |> Accounts.get_user()
      |> Accounts.preload_current_subscription()

    {:ok,
     socket
     |> assign(profile_user: profile_user)
     |> assign_profile_form()}
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    profile_user = Accounts.preload_current_subscription(socket.assigns.current_user)

    {:ok,
     socket
     |> assign(profile_user: profile_user)
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

  @impl Phoenix.LiveView
  def handle_event("toggle_admin", _params, socket) do
    case Accounts.toggle_admin(socket.assigns.profile_user) do
      {:ok, updated_user} ->
        {:noreply, assign(socket, profile_user: updated_user)}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("grant_pro", %{"expires_at" => ""}, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("grant_pro", %{"expires_at" => date_str}, socket) do
    with {:ok, date} <- Date.from_iso8601(date_str),
         expires_at = DateTime.new!(date, ~T[23:59:59.000000], "Etc/UTC"),
         {:ok, _sub} <- Accounts.set_pro_subscription(socket.assigns.profile_user, expires_at) do
      {:noreply, reload_subscription(socket)}
    else
      _error -> {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("grant_pro_indefinitely", _params, socket) do
    case Accounts.set_pro_subscription(socket.assigns.profile_user) do
      {:ok, _sub} -> {:noreply, reload_subscription(socket)}
      {:error, _changeset} -> {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("revoke_pro", _params, socket) do
    case Accounts.revoke_subscription(socket.assigns.profile_user) do
      {:ok, _deleted} -> {:noreply, reload_subscription(socket)}
      {:error, _changeset} -> {:noreply, socket}
    end
  end

  defp assign_profile_form(socket) do
    form =
      socket.assigns.profile_user
      |> Accounts.change_user()
      |> to_form()

    assign(socket, form: form)
  end

  defp reload_subscription(socket) do
    user = %{
      socket.assigns.profile_user
      | current_subscription: Accounts.get_current_subscription(socket.assigns.profile_user)
    }

    assign(socket, profile_user: user)
  end
end
