defmodule JokerCynic.AI.OpenAIResponse do
  @moduledoc false
  use Ecto.Schema

  @type t() :: %__MODULE__{}

  @primary_key false
  schema "ai_responses" do
    field :message_id, Ch, type: "Int64"
    field :chat_id, Ch, type: "Int64"

    field :user_id, Ch, type: "Int64"

    field :text, Ch, type: "String"
    field :prompt_tokens, Ch, type: "Int64"
    field :completion_tokens, Ch, type: "Int64"
    field :model, Ch, type: "String"

    timestamps(type: :utc_datetime)
  end

  @spec cast(map()) :: {:ok, t()} | :error
  def cast(response) do
    with {:ok, text} <- cast_text(response),
         {:ok, prompt_tokens} <- cast_token_usage(response, "prompt_tokens"),
         {:ok, completion_tokens} <- cast_token_usage(response, "completion_tokens"),
         {:ok, model} <- cast_model(response) do
      {:ok,
       %__MODULE__{
         text: text,
         prompt_tokens: prompt_tokens,
         completion_tokens: completion_tokens,
         model: model
       }}
    end
  end

  defp cast_text(response) do
    response
    |> Access.get("choices")
    |> List.wrap()
    |> List.first()
    |> Access.get("message")
    |> Access.get("content")
    |> validate_not_nil()
  end

  defp cast_token_usage(response, key) do
    response
    |> Access.get("usage")
    |> Access.get(key)
    |> validate_not_nil()
  end

  defp cast_model(response) do
    response
    |> Access.get("model")
    |> validate_not_nil()
  end

  defp validate_not_nil(value) do
    if value, do: {:ok, value}, else: :error
  end
end
