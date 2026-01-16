defmodule AnyTalkerWeb.WebApp.ChatLive do
  @moduledoc false
  use AnyTalkerWeb, :live_view

  import AnyTalkerWeb.TelegramComponents

  alias AnyTalker.Accounts
  alias AnyTalker.Settings

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div id="back-init" phx-hook="TelegramBack" data-state="on"></div>
    <div class="space-y-5">
      <.section class="pt-[30px] pb-[15px]">
        <div class="flex justify-center">
          <img src={~p"/avatar/#{@chat_config.id}"} class="rounded-full" width="90" height="90" alt="Chat photo" />
        </div>
        <h1 class="mt-[15px] text-center text-xl font-bold">{@chat_config.title}</h1>
      </.section>

      <.section>
        <.link
          navigate={~p"/webapp/c/#{@chat_config.id}/statistics"}
          class="hover-effect text-[15px] flex items-center justify-center gap-2 py-2"
        >
          <span>Статистика сообщений</span>
          <span class="text-tg-hint">→</span>
        </.link>
      </.section>

      <.section>
        <.link
          navigate={~p"/webapp/c/#{@chat_config.id}/move_stats"}
          class="hover-effect text-[15px] flex items-center justify-center gap-2 py-2"
        >
          <span>Статистика /move</span>
          <span class="text-tg-hint">→</span>
        </.link>
      </.section>

      <.section :if={@user_owner?}>
        <:header>Настройки</:header>
        <div class="px-2">
          <.form for={@form} phx-change="validate" phx-submit="save">
            <.switch label="Антиспам" field={@form[:antispam]} />
            <.switch label="Команда /ask" field={@form[:ask_command]} />
            <.switch label="Реклама PRO" field={@form[:promote_pro]} />
            <.tg_input label="Имя бота" field={@form[:bot_name]} />
            <.tg_input label="Таймзона" field={@form[:timezone]} />
            <.tg_input label="Модели /ask" field={@form[:ask_model]} />
            <.tg_input type="number" label="Макс. токенов /ask" field={@form[:ask_max_tokens]} />
            <.tg_input
              type="number"
              label="Интервал пополнения /ask (мс)"
              field={@form[:ask_refill_interval_ms]}
            />
            <.tg_input type="number" label="Пополнение токенов /ask" field={@form[:ask_refill_amount]} />
            <div class="mt-2">
              <.textarea label="Промпт /ask" field={@form[:ask_prompt]} />
            </div>
            <div class="px-1 pt-3">
              <button
                type="submit"
                phx-disable-with="Сохранение..."
                class="w-full rounded-lg bg-blue-600 px-4 py-2 font-medium text-white transition-colors hover:bg-blue-700"
              >
                Сохранить
              </button>
            </div>
          </.form>
        </div>
      </.section>

      <.users_section :if={@user_owner?} users={@chat_members} />
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(%{"chat_id" => chat_id}, _session, socket) do
    user_owner? = Accounts.owner?(socket.assigns.current_user)

    chat_config = Settings.get_chat_config(chat_id)
    chat_members = Accounts.list_chat_members(chat_id)

    Task.async(fn ->
      Settings.get_or_fetch_chat_avatar(chat_id)
    end)

    {:ok,
     socket
     |> assign(user_owner?: user_owner?, chat_members: chat_members)
     |> assign_chat_config(chat_config)}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"chat_config" => attrs}, socket) do
    chat_config = socket.assigns.chat_config

    changeset =
      chat_config
      |> Settings.change_chat_config(attrs)
      |> Map.put(:action, :validate)

    form = to_form(changeset)

    {:noreply, assign(socket, form: form)}
  end

  @impl Phoenix.LiveView
  def handle_event("save", %{"chat_config" => attrs}, socket) do
    chat_config = socket.assigns.chat_config
    user_owner? = socket.assigns.user_owner?

    if user_owner? do
      case Settings.update_chat_config(chat_config, attrs) do
        {:ok, new_config} ->
          {:noreply, assign_chat_config(socket, new_config)}

        {:error, _error_changeset} ->
          {:noreply, assign_chat_config(socket, chat_config)}
      end
    else
      {:noreply, assign_chat_config(socket, chat_config)}
    end
  end

  defp assign_chat_config(socket, chat_config) do
    form =
      chat_config
      |> Settings.change_chat_config()
      |> to_form()

    assign(socket, form: form, chat_config: chat_config)
  end
end
