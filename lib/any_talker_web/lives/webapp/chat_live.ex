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
    <.section class="pt-[30px] pb-[15px]">
      <div class="flex justify-center">
        <img src class="rounded-full" width="90" height="90" alt="Chat photo" />
      </div>
      <h1 class="mt-[15px] text-center text-xl font-bold">{@chat_config.title}</h1>
    </.section>

    <.section :if={@user_owner?} class="mt-5">
      <:header>Настройки</:header>
      <div class="px-2">
        <.form for={@form} phx-change="save">
          <.switch label="Антиспам" field={@form[:antispam]} />
          <.switch label="Команда /ask" field={@form[:ask_command]} />
          <.input type="textarea" label="Промпт /ask" field={@form[:ask_prompt]} />
        </.form>
      </div>
    </.section>
    """
  end

  @impl Phoenix.LiveView
  def mount(%{"chat_id" => id}, _session, socket) do
    user_owner? = Accounts.owner?(socket.assigns.current_user)

    chat_config = Settings.get_chat_config(id)

    {:ok,
     socket
     |> assign(user_owner?: user_owner?)
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
end
