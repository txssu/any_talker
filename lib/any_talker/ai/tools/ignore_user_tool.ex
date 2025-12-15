defmodule AnyTalker.AI.IgnoreUserTool do
  @moduledoc false
  use AnyTalker.AI.Tool, type: :function

  alias AnyTalker.Accounts
  alias AnyTalker.AI.Context
  alias AnyTalker.AI.Function
  alias AnyTalker.AI.Tool

  @scale to_timeout(hour: 1000)

  @tool_description """
  Используется для временного прекращения ответа пользователю, когда продолжение диалога становится невозможным по причинам поведения, а не лексики.
  Мат, ругань и оскорбительные слова сами по себе полностью игнорируются и никогда не являются причиной использования этого инструмента.

  Инструмент применяется ТОЛЬКО если:
  – пользователь использует жёсткие адресные оскорбления или унижение (допускается с первого сообщения);
  – имеет место повторяющаяся травля или саботаж общения (паттерн, а не одно сообщение);
  – присутствуют угрозы или призывы к насилию;
  – происходит атака на третьих лиц или защищаемые объекты.

  Инструмент НЕ применяется:
  – из-за мата без оскорбительного намерения;
  – из-за резкой, но предметной критики;
  – из-за резкой критики или эмоциональной агрессии;
  – если диалог можно продолжать по существу.

  После вызова инструмента ассистент ОБЯЗАН отправить пользователю заключительное текстовое сообщение, а не молчать полностью.

  Score отражает степень эскалации и намерение сломать диалог, а не «насколько обидно».
  """

  @score_description """
  Целое число от 1 до 10. Отражает степень эскалации поведения пользователя и явность намерения прекратить или разрушить диалог.
  Мат и оскорбительная лексика не влияют на значение score.

  1–2 — единичные попытки подавить диалог
  3–4 — повторяющиеся попытки прекратить общение
  5–6 — систематическая травля или саботаж разговора
  7–8 — атаки на третьих лиц или защищаемые объекты
  9–10 — угрозы, призывы к насилию, тяжёлая эскалация
  """

  @reason_description """
  Краткое, нейтральное объяснение причины игнора без эмоциональной оценки.
  Формулируется как констатация поведения, а не личная обида.
  """

  @impl Tool
  def spec do
    %{
      type: "function",
      name: name(),
      description: @tool_description,
      strict: true,
      parameters: %{
        type: "object",
        additionalProperties: false,
        properties: %{
          score: %{
            type: "integer",
            description: @score_description,
            minimum: 1,
            maximum: 10
          },
          reason: %{
            type: "string",
            description: @reason_description
          }
        },
        required: ["score", "reason"]
      }
    }
  end

  @impl Function
  def name, do: "ignore_user"

  @impl Function
  def exec(params, %Context{user_id: user_id}) do
    score = params["score"]
    duration = div(score * @scale, 10)
    ignore_until = DateTime.add(DateTime.utc_now(), duration, :millisecond)

    case Accounts.get_user(user_id) do
      nil ->
        %{"error" => "User not found"}

      user ->
        case Accounts.ignore_user(user, ignore_until) do
          {:ok, _user} -> "ok"
          {:error, _changeset} -> %{"error" => "Failed to ignore user"}
        end
    end
  end
end
