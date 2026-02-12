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
      <:header>Настройки</:header>
      <.form for={@form} phx-change="validate" phx-submit="save">
        <div class="space-y-3">
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
  def handle_event("validate", %{"global_config" => attrs}, socket) do
    config = socket.assigns.global_config

    changeset =
      config
      |> GlobalConfig.change_config(attrs)
      |> Map.put(:action, :validate)

    form = to_form(changeset)

    {:noreply, assign(socket, form: form)}
  end

  @impl Phoenix.LiveView
  def handle_event("save", %{"global_config" => attrs}, socket) do
    config = socket.assigns.global_config
    old_model = config.ask_model

    case GlobalConfig.update_config(config, attrs) do
      {:ok, new_config} ->
        socket = assign_config(socket, new_config)
        socket = if new_config.ask_model == old_model, do: socket, else: fetch_models_info(socket, new_config.ask_model)

        {:noreply, socket}

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

  defp fetch_models_info(socket, model_string) do
    model_ids = parse_model_ids(model_string)

    assign_async(socket, :models_info, fn ->
      {:ok, %{models_info: ModelInfo.get_many(model_ids)}}
    end)
  end

  defp parse_model_ids(nil), do: []
  defp parse_model_ids(model_string), do: String.split(model_string, " ", trim: true)
end
