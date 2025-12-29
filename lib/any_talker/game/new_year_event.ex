defmodule AnyTalker.Game.NewYearEvent do
  @moduledoc """
  Логика новогоднего события 2025-2026.
  Модуль можно удалить после завершения события.
  """

  @ekb_timezone "Asia/Yekaterinburg"

  @doc """
  Returns the current event phase based on Ekaterinburg time.

  ## Returns
  - `:normal` - Before Dec 31 2025 (normal game behavior)
  - `:phase_1` - Dec 31 2025 00:00-23:59
  - `:phase_2` - Jan 1 2026 onwards
  """
  def current_phase do
    ekb_now = DateTime.shift_zone!(DateTime.utc_now(), @ekb_timezone)

    cond do
      ekb_now.year == 2025 and ekb_now.month == 12 and ekb_now.day == 31 -> :phase_1
      ekb_now.year >= 2026 -> :phase_2
      true -> :normal
    end
  end

  @doc """
  Checks if the New Year event is active (Phase 1 or Phase 2).
  """
  def event_active?, do: current_phase() in [:phase_1, :phase_2]

  @doc """
  Returns rate limit in milliseconds for current phase.
  Returns nil if default rate limit should be used.
  """
  def rate_limit_scale_ms do
    case current_phase() do
      :phase_1 -> 10_800_000
      _other -> nil
    end
  end

  @doc """
  Returns the rate limit message for current phase.
  """
  def rate_limit_message do
    case current_phase() do
      :phase_1 -> "Вы слишком устали. Путь стал тяжелее — силы возвращаются медленнее."
      _other -> "Вы слишком устали, чтобы двигаться дальше"
    end
  end

  @doc """
  Returns the special move message for Phase 1.
  """
  def phase_1_move_message do
    "Тропа становится уже. Воздух — плотнее. Под ногами — не земля. Что-то другое. Тропа ещё есть, но она... истончается."
  end

  @doc """
  Returns the final step message for Phase 2.
  """
  def final_step_message do
    "Ты шёл, потому что мог. Теперь не можешь. Не потому что устал. Просто — некуда. Впереди ничего. И ты наконец понимаешь: ничего и не было. Только шаги. Только движение. Только ты, пока ты ещё был."
  end

  @doc """
  Checks if the command should be completely ignored (Phase 2 after final step).
  """
  def should_ignore_command?(has_taken_final_step) do
    current_phase() == :phase_2 and has_taken_final_step
  end

  @doc """
  Checks if user can take their final step (Phase 2, hasn't taken final step yet).
  """
  def can_take_final_step?(has_taken_final_step) do
    current_phase() == :phase_2 and not has_taken_final_step
  end
end
