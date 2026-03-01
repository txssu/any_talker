defmodule AnyTalkerBot.Shared.Ask do
  @moduledoc false

  import AnyTalker.LocalizationUtils

  alias AnyTalker.Accounts
  alias AnyTalker.Accounts.Subscription
  alias AnyTalker.Accounts.User
  alias AnyTalker.AI.Response
  alias AnyTalker.RateLimit.Context
  alias AnyTalker.RateLimit.TokenBucket
  alias AnyTalker.Settings.ChatConfig

  @time_buffer_ms to_timeout(minute: 5)

  def validate_not_banned(%User{ask_banned: true}), do: {:error, :banned}
  def validate_not_banned(%User{}), do: :ok

  def validate_pro(%User{current_subscription: %Subscription{plan: :pro}}), do: :ok
  def validate_pro(%User{} = user), do: if(Accounts.owner?(user), do: :ok, else: {:error, :not_pro})

  def validate_rate_limit(%User{} = user, %ChatConfig{} = config) do
    key = "ask:#{user.id}"

    context = %Context{
      max_tokens: config.ask_max_tokens,
      refill_interval_ms: config.ask_refill_interval_ms,
      refill_amount: config.ask_refill_amount
    }

    if TokenBucket.allowed?(key, context) do
      :ok
    else
      time_left_ms = TokenBucket.time_until_allowed(key, context) || context.refill_interval_ms
      {:error, :rate_limit, time_left_ms}
    end
  end

  def consume_tokens(%User{} = user, %ChatConfig{} = config, %Response{} = response) do
    tokens_used = Response.total_tokens(response)

    if tokens_used > 0 do
      key = "ask:#{user.id}"

      context = %Context{
        max_tokens: config.ask_max_tokens,
        refill_interval_ms: config.ask_refill_interval_ms,
        refill_amount: config.ask_refill_amount
      }

      TokenBucket.increase(key, tokens_used, context)
    end
  end

  def replace_keywords(text) do
    text
    |> String.replace(~r/\bдостаточно\b/iu, "#достаточно")
    |> String.replace(~r/\bне\s+нужно\b/iu, "#ненужно")
  end

  def format_time(time_left_ms) do
    time_with_buffer_ms = time_left_ms + @time_buffer_ms

    hours = div(time_with_buffer_ms, 3_600_000)
    minutes = div(rem(time_with_buffer_ms, 3_600_000), 60_000)

    [format_unit(hours, "час", "часа", "часов"), format_unit(minutes, "минуту", "минуты", "минут")]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
  end

  defp format_unit(0, _singular, _few, _many), do: nil
  defp format_unit(n, singular, few, many), do: "#{n} #{pluralize(n, singular, few, many)}"
end
