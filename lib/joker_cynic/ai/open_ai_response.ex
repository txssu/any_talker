defmodule JokerCynic.AI.OpenAIResponse do
  @moduledoc false
  use TypedStruct

  require Logger

  typedstruct do
    field :message_id, integer()
    field :chat_id, integer()
    field :user_id, integer()
    field :text, String.t()
    field :prompt_tokens, integer()
    field :completion_tokens, integer()
    field :model, String.t()
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
