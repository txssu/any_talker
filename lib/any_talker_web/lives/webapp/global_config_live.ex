defmodule AnyTalkerWeb.WebApp.GlobalConfigLive do
  @moduledoc false
  use AnyTalkerWeb, :live_view

  import AnyTalkerWeb.TelegramComponents

  alias AnyTalker.GlobalConfig

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div id="back-init" phx-hook="TelegramBack" data-state="on"></div>
    <.section class="pt-[30px] pb-[15px]">
      <h1 class="mt-[15px] text-center text-xl font-bold">Глобальные настройки</h1>
    </.section>

    <.section class="mt-5">
      <:header>Настройки</:header>
      <.form for={@form} phx-change="save">
        <div class="space-y-3">
          <.tg_input label="Модель /ask" field={@form[:ask_model]} />
          <.tg_input type="number" label="Лимит запросов /ask" field={@form[:ask_rate_limit]} />
          <.tg_input type="number" label="Период лимита /ask (мс)" field={@form[:ask_rate_limit_scale_ms]} />
          <div class="mt-2">
            <.textarea label="Промпт /ask" field={@form[:ask_prompt]} />
          </div>
        </div>
      </.form>
    </.section>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    config = GlobalConfig.get_config()

    {:ok, assign_config(socket, config)}
  end

  @impl Phoenix.LiveView
  def handle_event("back", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/webapp")}
  end

  @impl Phoenix.LiveView
  def handle_event("save", %{"global_config" => attrs}, socket) do
    config = socket.assigns.global_config

    case GlobalConfig.update_config(config, attrs) do
      {:ok, new_config} ->
        {:noreply, assign_config(socket, new_config)}

      {:error, _changeset} ->
        {:noreply, assign_config(socket, config)}
    end
  end

  defp assign_config(socket, config) do
    form =
      config
      |> GlobalConfig.change_config()
      |> to_form()

    assign(socket, form: form, global_config: config)
  end
end
