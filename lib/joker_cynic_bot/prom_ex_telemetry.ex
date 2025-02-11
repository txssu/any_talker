# credo:disable-for-this-file Credo.Check.Refactor.AppendSingleItem
defmodule JokerCynicBot.PromExTelemetry do
  @moduledoc false
  use PromEx.Plugin

  @impl PromEx.Plugin
  def event_metrics(opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)
    metric_prefix = Keyword.get(opts, :metric_prefix, PromEx.metric_prefix(otp_app, :bot))

    Event.build(
      :joker_cynic_event_metrics,
      [
        distribution(metric_prefix ++ [:handle_time],
          event_name: [:joker_cynic, :bot],
          measurement: :handle_time,
          reporter_options: [buckets: [50, 150, 400, 1000, 2_500, 10_000, 30_000]],
          unit: {:native, :millisecond}
        ),
        token_metric(metric_prefix, :prompt_tokens),
        token_metric(metric_prefix, :completion_tokens),
        token_metric(metric_prefix, :total_tokens),
        counter(metric_prefix ++ [:ai, :total_tokens, :counter],
          event_name: [:joker_cynic, :bot, :ai],
          measurement: :total_tokens,
          tags: [:model]
        )
      ]
    )
  end

  def token_metric(metric_prefix, name) do
    sum(metric_prefix ++ [:ai, name, :sum],
      event_name: [:joker_cynic, :bot, :ai],
      measurement: name,
      tags: [:model]
    )
  end
end
