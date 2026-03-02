defmodule AnyTalkerWeb.WebApp.GlobalConfigLive do
  @moduledoc false
  use AnyTalkerWeb, :live_view

  import AnyTalkerWeb.TelegramComponents

  alias AnyTalker.AI.ModelInfo
  alias AnyTalker.GlobalConfig

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div id="back-init" phx-hook="TelegramBack" data-state="on"></div>
    <.section class="pt-[30px] pb-[15px]">
      <h1 class="mt-[15px] text-center text-xl font-bold">Глобальные настройки</h1>
    </.section>

    <.section class="mt-5">
      <:header>Общее</:header>
      <.form for={@general_form} phx-change="validate_general" phx-submit="save_general">
        <div class="space-y-3">
          <.tg_input label="Таймзона" field={@general_form[:timezone]} />
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

    <.section class="mt-5">
      <:header>Модель /ask</:header>
      <.form for={@ask_model_form} phx-change="validate_ask_model" phx-submit="save_ask_model">
        <div class="space-y-3">
          <.tg_input label="Модели /ask" field={@ask_model_form[:ask_model]} />
          <div class="mt-2">
            <.textarea label="Промпт /ask" field={@ask_model_form[:ask_prompt]} />
          </div>
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

    <.section :if={@models_info.loading} class="mt-5">
      <:header>Модели</:header>
      <p class="text-[15px] text-tg-hint mt-2.5 text-center">Загрузка информации о моделях...</p>
    </.section>

    <.section :if={@models_info.failed} class="mt-5">
      <:header>Модели</:header>
      <p class="text-[15px] text-tg-hint mt-2.5 text-center">Не удалось загрузить информацию о моделях</p>
    </.section>

    <.section :if={@models_info.ok? && @models_info.result != %{}} class="mt-5">
      <:header>Модели</:header>
      <div class="mt-2 space-y-3">
        <.model_card :for={{model_id, result} <- @models_info.result} id={model_id} result={result} />
      </div>
    </.section>

    <.section class="mt-5">
      <:header>Лимиты /ask</:header>
      <.form for={@ask_limits_form} phx-change="validate_ask_limits" phx-submit="save_ask_limits">
        <div class="space-y-3">
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

  defp model_card(%{result: {:ok, model}} = assigns) do
    assigns = assign(assigns, :model, model)

    ~H"""
    <div class="bg-tg-section-bg rounded-lg p-3">
      <div class="text-[15px] font-medium">{@model.name}</div>
      <div class="text-[13px] text-tg-hint mt-0.5">{@model.id}</div>
      <div :if={@model.architecture} class="text-[13px] text-tg-hint mt-1">
        {format_modalities(@model.architecture)}
      </div>
      <div :if={pricing_range(@model) != []} class="text-[13px] text-tg-hint mt-1">
        {format_pricing_range(pricing_range(@model))}
      </div>
    </div>
    """
  end

  defp model_card(%{result: {:error, _reason}} = assigns) do
    ~H"""
    <div class="bg-tg-section-bg rounded-lg p-3">
      <div class="text-[15px] font-medium">{@id}</div>
      <div class="text-[13px] text-tg-hint mt-0.5">Не удалось загрузить</div>
    </div>
    """
  end

  defp format_modalities(architecture) do
    input = architecture["input_modalities"] || []
    output = architecture["output_modalities"] || []

    "#{Enum.join(input, ", ")} → #{Enum.join(output, ", ")}"
  end

  defp pricing_range(%{endpoints: endpoints}) do
    endpoints
    |> Enum.map(& &1.pricing)
    |> Enum.reject(&is_nil/1)
  end

  defp format_pricing_range(pricings) do
    prompt_range = format_range(pricings, & &1.prompt)
    completion_range = format_range(pricings, & &1.completion)

    "$#{prompt_range} / $#{completion_range} за 1M токенов"
  end

  defp format_range(pricings, field_fn) do
    {min, max} = min_max(pricings, field_fn)

    if Decimal.equal?(min, max),
      do: per_million(min),
      else: "#{per_million(min)}–#{per_million(max)}"
  end

  defp min_max(pricings, field_fn) do
    values =
      pricings
      |> Enum.map(field_fn)
      |> Enum.reject(&is_nil/1)

    {Enum.min(values, Decimal), Enum.max(values, Decimal)}
  end

  defp per_million(nil), do: "—"

  defp per_million(price_per_token) do
    price_per_token
    |> Decimal.mult(1_000_000)
    |> Decimal.round(2)
    |> Decimal.to_string(:normal)
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    config = GlobalConfig.get_config()

    socket =
      socket
      |> assign_config(config)
      |> fetch_models_info(config.ask_model)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("validate_general", %{"general" => attrs}, socket) do
    changeset =
      socket.assigns.global_config
      |> GlobalConfig.change_general(attrs)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, general_form: to_form(changeset, as: "general"))}
  end

  def handle_event("save_general", %{"general" => attrs}, socket) do
    config = socket.assigns.global_config

    case GlobalConfig.update_general(config, attrs) do
      {:ok, new_config} -> {:noreply, assign_config(socket, new_config)}
      {:error, _changeset} -> {:noreply, assign_config(socket, config)}
    end
  end

  def handle_event("validate_ask_model", %{"ask_model" => attrs}, socket) do
    changeset =
      socket.assigns.global_config
      |> GlobalConfig.change_ask_model(attrs)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, ask_model_form: to_form(changeset, as: "ask_model"))}
  end

  def handle_event("save_ask_model", %{"ask_model" => attrs}, socket) do
    config = socket.assigns.global_config
    old_model = config.ask_model

    case GlobalConfig.update_ask_model(config, attrs) do
      {:ok, new_config} ->
        socket = assign_config(socket, new_config)
        socket = if new_config.ask_model == old_model, do: socket, else: fetch_models_info(socket, new_config.ask_model)
        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, assign_config(socket, config)}
    end
  end

  def handle_event("validate_ask_limits", %{"ask_limits" => attrs}, socket) do
    changeset =
      socket.assigns.global_config
      |> GlobalConfig.change_ask_limits(attrs)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, ask_limits_form: to_form(changeset, as: "ask_limits"))}
  end

  def handle_event("save_ask_limits", %{"ask_limits" => attrs}, socket) do
    config = socket.assigns.global_config

    case GlobalConfig.update_ask_limits(config, attrs) do
      {:ok, new_config} -> {:noreply, assign_config(socket, new_config)}
      {:error, _changeset} -> {:noreply, assign_config(socket, config)}
    end
  end

  defp assign_config(socket, config) do
    socket
    |> assign(:global_config, config)
    |> assign(:general_form, to_form(GlobalConfig.change_general(config), as: "general"))
    |> assign(:ask_model_form, to_form(GlobalConfig.change_ask_model(config), as: "ask_model"))
    |> assign(:ask_limits_form, to_form(GlobalConfig.change_ask_limits(config), as: "ask_limits"))
  end

  defp fetch_models_info(socket, model_string) do
    model_ids = parse_model_ids(model_string)

    assign_async(socket, :models_info, fn ->
      {:ok, %{models_info: ModelInfo.get_many(model_ids)}}
    end)
  end

  defp parse_model_ids(nil), do: []
  defp parse_model_ids(model_string), do: String.split(model_string, " ", trim: true)
end
