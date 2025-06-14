defmodule AnyTalkerWeb.WebApp.ChatLive do
  @moduledoc false
  use AnyTalkerWeb, :live_view

  import AnyTalker.LocalizationUtils, only: [pluralize: 4]
  import AnyTalkerWeb.TelegramComponents

  alias AnyTalker.Accounts
  alias AnyTalker.Settings
  alias AnyTalker.Statistics

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div id="back-init" phx-hook="TelegramBack" data-state="on"></div>
    <div class="space-y-5">
      <.section class="pt-[30px] pb-[15px]">
        <div class="flex justify-center">
          <img src class="rounded-full" width="90" height="90" alt="Chat photo" />
        </div>
        <h1 class="mt-[15px] text-center text-xl font-bold">{@chat_config.title}</h1>
      </.section>

      <.section>
        <:header>Топ 5 отправителей за сегодня</:header>
        <p :if={@top_authors == []} class="text-[15px] text-tg-hint mt-2.5 text-center">Сегодня не было сообщений</p>
        <ul :if={@top_authors != []}>
          <li :for={author <- @top_authors}>
            <a
              href={"https://t.me/#{author.user.username}"}
              class="border-tg-section-separator hover-effect h-[42px] flex items-center rounded-lg border-b-2 pl-5 last:border-b-0"
            >
              <span class="text-[15px] flex-1 py-2.5">
                {username(author.user)} — {author.message_count} {message_word(author.message_count)}
              </span>
            </a>
          </li>
        </ul>
      </.section>

      <.section :if={@user_owner?}>
        <:header>Настройки</:header>
        <div class="px-2">
          <.form for={@form} phx-change="save">
            <.switch label="Антиспам" field={@form[:antispam]} />
            <.switch label="Команда /ask" field={@form[:ask_command]} />
            <div class="mt-2">
              <.textarea label="Промпт /ask" field={@form[:ask_prompt]} />
            </div>
          </.form>
        </div>
      </.section>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(%{"chat_id" => id}, _session, socket) do
    user_owner? = Accounts.owner?(socket.assigns.current_user)

    chat_config = Settings.get_chat_config(id)
    top_authors = Statistics.get_top_message_authors_today(id, 5)

    {:ok,
     socket
     |> assign(user_owner?: user_owner?, top_authors: top_authors)
     |> assign_chat_config(chat_config)}
  end

  @impl Phoenix.LiveView
  def handle_event("back", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/webapp")}
  end

  @impl Phoenix.LiveView
  def handle_event("save", %{"chat_config" => attrs}, socket) do
    chat_config = socket.assigns.chat_config
    user_owner? = socket.assigns.user_owner?

    if user_owner? do
      case Settings.update_chat_config(chat_config, attrs) do
        {:ok, new_config} ->
          {:noreply, assign_chat_config(socket, new_config)}

        {:error, _changeset} ->
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

  defp username(nil), do: "Неизвестный пользователь"
  defp username(user), do: Accounts.display_name(user) || user.username

  defp message_word(count), do: pluralize(count, "сообщение", "сообщения", "сообщений")
end
