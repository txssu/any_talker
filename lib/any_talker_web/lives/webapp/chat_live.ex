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

      <.section :if={@user_owner?}>
        <:header>Антиспам</:header>
        <div class="px-2">
          <.form for={@antispam_form} phx-change="validate_antispam" phx-submit="save_antispam">
            <.switch label="Капча для новых участников" field={@antispam_form[:antispam_captcha]} />
            <.switch label="Удалять via-сообщения" field={@antispam_form[:antispam_via]} />
            <.switch label="Фильтр ключевых слов" field={@antispam_form[:antispam_keywords_enabled]} />
            <.tg_input label="Ключевые слова антиспама" field={@antispam_form[:antispam_keywords]} />
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

      <.section :if={@user_owner?}>
        <:header>Команда /ask</:header>
        <div class="px-2">
          <.form for={@ask_command_form} phx-change="validate_ask_command" phx-submit="save_ask_command">
            <.switch label="Команда /ask" field={@ask_command_form[:ask_command]} />
            <.tg_input label="Имя бота" field={@ask_command_form[:bot_name]} />
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

      <.section :if={@user_owner?}>
        <:header>Модель /ask</:header>
        <div class="px-2">
          <.form for={@ask_model_form} phx-change="validate_ask_model" phx-submit="save_ask_model">
            <.tg_input label="Модели /ask" field={@ask_model_form[:ask_model]} />
            <div class="mt-2">
              <.textarea label="Промпт /ask" field={@ask_model_form[:ask_prompt]} />
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

      <.section :if={@user_owner?}>
        <:header>Лимиты /ask</:header>
        <div class="px-2">
          <.form for={@ask_limits_form} phx-change="validate_ask_limits" phx-submit="save_ask_limits">
            <.tg_input type="number" label="Макс. токенов /ask" field={@ask_limits_form[:ask_max_tokens]} />
            <.tg_input
              type="number"
              label="Интервал пополнения /ask (мс)"
              field={@ask_limits_form[:ask_refill_interval_ms]}
            />
            <.tg_input
              type="number"
              label="Пополнение токенов /ask"
              field={@ask_limits_form[:ask_refill_amount]}
            />
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

      <.section :if={@user_owner?}>
        <:header>Общее</:header>
        <div class="px-2">
          <.form for={@general_form} phx-change="validate_general" phx-submit="save_general">
            <.switch label="Реклама PRO" field={@general_form[:promote_pro]} />
            <.tg_input label="Таймзона" field={@general_form[:timezone]} />
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

    Task.async(fn -> Settings.get_or_fetch_chat_avatar(chat_id) end)

    {:ok,
     socket
     |> assign(user_owner?: user_owner?, chat_members: chat_members)
     |> assign_chat_config(chat_config)}
  end

  @impl Phoenix.LiveView
  def handle_event("validate_antispam", %{"antispam" => attrs}, socket) do
    changeset =
      socket.assigns.chat_config
      |> Settings.change_antispam_config(attrs)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, antispam_form: to_form(changeset, as: "antispam"))}
  end

  def handle_event("save_antispam", %{"antispam" => attrs}, socket) do
    save_section(
      socket,
      attrs,
      &Settings.update_antispam_config/2,
      :antispam_form,
      "antispam",
      &Settings.change_antispam_config/2
    )
  end

  def handle_event("validate_ask_command", %{"ask_command" => attrs}, socket) do
    changeset =
      socket.assigns.chat_config
      |> Settings.change_ask_command_config(attrs)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, ask_command_form: to_form(changeset, as: "ask_command"))}
  end

  def handle_event("save_ask_command", %{"ask_command" => attrs}, socket) do
    save_section(
      socket,
      attrs,
      &Settings.update_ask_command_config/2,
      :ask_command_form,
      "ask_command",
      &Settings.change_ask_command_config/2
    )
  end

  def handle_event("validate_ask_model", %{"ask_model" => attrs}, socket) do
    changeset =
      socket.assigns.chat_config
      |> Settings.change_ask_model_config(attrs)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, ask_model_form: to_form(changeset, as: "ask_model"))}
  end

  def handle_event("save_ask_model", %{"ask_model" => attrs}, socket) do
    save_section(
      socket,
      attrs,
      &Settings.update_ask_model_config/2,
      :ask_model_form,
      "ask_model",
      &Settings.change_ask_model_config/2
    )
  end

  def handle_event("validate_ask_limits", %{"ask_limits" => attrs}, socket) do
    changeset =
      socket.assigns.chat_config
      |> Settings.change_ask_limits_config(attrs)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, ask_limits_form: to_form(changeset, as: "ask_limits"))}
  end

  def handle_event("save_ask_limits", %{"ask_limits" => attrs}, socket) do
    save_section(
      socket,
      attrs,
      &Settings.update_ask_limits_config/2,
      :ask_limits_form,
      "ask_limits",
      &Settings.change_ask_limits_config/2
    )
  end

  def handle_event("validate_general", %{"general" => attrs}, socket) do
    changeset =
      socket.assigns.chat_config
      |> Settings.change_general_chat_config(attrs)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, general_form: to_form(changeset, as: "general"))}
  end

  def handle_event("save_general", %{"general" => attrs}, socket) do
    save_section(
      socket,
      attrs,
      &Settings.update_general_chat_config/2,
      :general_form,
      "general",
      &Settings.change_general_chat_config/2
    )
  end

  defp save_section(socket, attrs, update_fn, form_key, form_name, change_fn) do
    chat_config = socket.assigns.chat_config
    user_owner? = socket.assigns.user_owner?

    if user_owner? do
      case update_fn.(chat_config, attrs) do
        {:ok, new_config} ->
          {:noreply,
           assign(socket, [
             {form_key, to_form(change_fn.(new_config, %{}), as: form_name)},
             {:chat_config, new_config}
           ])}

        {:error, _changeset} ->
          {:noreply, assign(socket, form_key, to_form(change_fn.(chat_config, %{}), as: form_name))}
      end
    else
      {:noreply, socket}
    end
  end

  defp assign_chat_config(socket, chat_config) do
    socket
    |> assign(:chat_config, chat_config)
    |> assign(:antispam_form, to_form(Settings.change_antispam_config(chat_config), as: "antispam"))
    |> assign(:ask_command_form, to_form(Settings.change_ask_command_config(chat_config), as: "ask_command"))
    |> assign(:ask_model_form, to_form(Settings.change_ask_model_config(chat_config), as: "ask_model"))
    |> assign(:ask_limits_form, to_form(Settings.change_ask_limits_config(chat_config), as: "ask_limits"))
    |> assign(:general_form, to_form(Settings.change_general_chat_config(chat_config), as: "general"))
  end
end
