defmodule AnyTalkerWeb.WebApp.InactiveUsersLive do
  @moduledoc false
  use AnyTalkerWeb, :live_view

  import AnyTalkerWeb.TelegramComponents

  alias AnyTalker.Accounts

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div id="back-init" phx-hook="TelegramBack" data-state="on"></div>
    <.section class="pt-[30px] pb-[15px]">
      <h1 class="mt-[15px] text-center text-xl font-bold">Неактивные пользователи</h1>
    </.section>

    <.section :if={@view_mode == :chat_selection} class="mt-5">
      <:header>Выберите чат</:header>
      <p :if={@chats == []} class="text-[15px] text-tg-hint mt-2.5 text-center">
        Нет доступных чатов
      </p>
      <ul :if={@chats != []}>
        <li :for={chat <- @chats}>
          <.link
            patch={~p"/webapp/inactive_users?chat_id=#{chat.id}"}
            class="border-tg-section-separator hover-effect h-[42px] flex items-center rounded-lg border-b-2 pl-5 last:border-b-0"
          >
            <span class="text-[15px] py-2.5">{chat.title}</span>
          </.link>
        </li>
      </ul>
    </.section>

    <div :if={@view_mode == :user_list}>
      <.section class="mt-5">
        <:header>{@selected_chat.title}</:header>
        <div class="mb-3 flex flex-col gap-2">
          <button
            phx-click="back_to_chats"
            class="hover-effect bg-tg-secondary-bg text-[15px] text-tg-text w-full rounded-lg px-4 py-2.5 font-medium"
          >
            Назад к выбору чата
          </button>
          <button
            id="copy-inactive-users"
            phx-hook="CopyToClipboard"
            data-text={@copy_text}
            class="hover-effect bg-tg-button text-[15px] text-tg-button-text w-full rounded-lg px-4 py-2.5 font-medium"
          >
            Копировать список
          </button>
        </div>
        <p :if={@users == []} class="text-[15px] text-tg-hint mt-2.5 text-center">
          Нет пользователей
        </p>
        <ul :if={@users != []}>
          <li :for={{user_data, position} <- @users_with_position}>
            <.link
              navigate={~p"/webapp/profile/#{user_data.user.id}"}
              class="border-tg-section-separator hover-effect flex items-center gap-3 rounded-lg border-b-2 px-3 py-2 last:border-b-0"
            >
              <div class="text-tg-hint text-[17px] w-8 flex-shrink-0 text-center font-bold">
                {position}
              </div>
              <img
                src={user_data.user.photo_url || ~p"/user_avatar/#{user_data.user.id}"}
                class="size-10 flex-shrink-0 rounded-full"
                alt="User photo"
              />
              <div class="flex min-w-0 flex-1 flex-col">
                <span class="text-[15px] truncate font-medium">
                  {user_data.user.first_name} {user_data.user.last_name}
                </span>
                <span :if={user_data.user.username} class="text-[13px] text-tg-hint truncate">
                  @{user_data.user.username}
                </span>
                <span class="text-[13px] text-tg-hint truncate">
                  {format_last_message_date(user_data.last_message_date)}
                </span>
              </div>
            </.link>
          </li>
        </ul>
      </.section>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    chats = Accounts.list_all_chats()

    socket =
      socket
      |> assign(:view_mode, :chat_selection)
      |> assign(:chats, chats)
      |> assign(:selected_chat, nil)
      |> assign(:users, [])
      |> assign(:users_with_position, [])
      |> assign(:copy_text, "")

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"chat_id" => chat_id_str}, _url, socket) do
    case Integer.parse(chat_id_str) do
      {chat_id, ""} ->
        selected_chat = Enum.find(socket.assigns.chats, &(&1.id == chat_id))

        case selected_chat do
          nil ->
            {:noreply, push_navigate(socket, to: ~p"/webapp/inactive_users")}

          chat ->
            users = Accounts.inactive_users_by_chat(50, chat_id)

            socket =
              socket
              |> assign(:view_mode, :user_list)
              |> assign(:selected_chat, chat)
              |> assign(:users, users)
              |> assign(:users_with_position, Enum.with_index(users, 1))
              |> assign(:copy_text, generate_copy_text(users))

            {:noreply, socket}
        end

      _error ->
        {:noreply, push_navigate(socket, to: ~p"/webapp/inactive_users")}
    end
  end

  def handle_params(_params, _url, socket) do
    {:noreply, assign(socket, :view_mode, :chat_selection)}
  end

  @impl Phoenix.LiveView
  def handle_event("back_to_chats", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/webapp/inactive_users")}
  end

  defp format_datetime(datetime) do
    datetime
    |> DateTime.shift_zone!("Asia/Yekaterinburg")
    |> Calendar.strftime("%d.%m.%Y %H:%M")
  end

  defp format_last_message_date(nil), do: "Никогда не писал"

  defp format_last_message_date(datetime) do
    "Последнее сообщение: #{format_datetime(datetime)}"
  end

  defp generate_copy_text(users) do
    users
    |> Enum.with_index(1)
    |> Enum.map_join("\n", fn {user_data, position} ->
      format_user_copy_line(position, user_data)
    end)
  end

  defp format_user_copy_line(position, %{user: user, last_message_date: last_message_date}) do
    date_str =
      if last_message_date do
        format_datetime(last_message_date)
      else
        "Никогда не писал"
      end

    user_str =
      if user.username do
        "t.me/#{user.username}"
      else
        "#{user.first_name} #{user.last_name} (#{user.id})"
      end

    "#{position}. #{user_str} - #{date_str}"
  end
end
