defmodule AnyTalker.PromEx do
  @moduledoc false
  use PromEx, otp_app: :any_talker

  alias PromEx.Plugins

  @impl PromEx
  def plugins do
    [
      Plugins.Application,
      Plugins.Beam,
      {Plugins.Phoenix, router: AnyTalkerWeb.Router, endpoint: AnyTalkerWeb.Endpoint},
      Plugins.Ecto,
      Plugins.Oban,
      Plugins.PhoenixLiveView,
      AnyTalkerBot.PromExTelemetry
    ]
  end

  @impl PromEx
  def dashboard_assigns do
    [
      datasource_id: "Prometheus",
      default_selected_interval: "30s"
    ]
  end

  @impl PromEx
  def dashboards do
    [
      {:prom_ex, "application.json"},
      {:prom_ex, "beam.json"},
      {:prom_ex, "phoenix.json"},
      {:prom_ex, "ecto.json"},
      {:prom_ex, "oban.json"},
      {:prom_ex, "phoenix_live_view.json"},
      {:any_talker, "grafana/bot.json"}
    ]
  end
end
