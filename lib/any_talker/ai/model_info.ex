defmodule AnyTalker.AI.ModelInfo do
  @moduledoc """
  Cached model info fetcher for OpenRouter models.

  Wraps `OpenRouterClient.model_info/1` with a 30-minute Nebulex cache
  to avoid excessive API calls.
  """
  use Nebulex.Caching

  alias AnyTalker.AI.OpenRouterClient
  alias AnyTalker.Cache

  @doc """
  Fetches model info for a single model ID, cached for 30 minutes.

      get("openai/gpt-4")
      {:ok, %Model{id: "openai/gpt-4", name: "GPT-4", ...}}
  """
  @decorate cacheable(cache: Cache, key: {__MODULE__, model_id}, opts: [ttl: to_timeout(minute: 30)])
  def get(model_id) do
    OpenRouterClient.model_info(model_id)
  end

  @doc """
  Fetches model info for multiple model IDs.

  Returns a list of `{model_id, {:ok, model} | {:error, reason}}` tuples.

      get_many(["openai/gpt-4", "anthropic/claude-3-opus"])
      [{"openai/gpt-4", {:ok, %Model{}}}, {"anthropic/claude-3-opus", {:ok, %Model{}}}]
  """
  def get_many(model_ids) do
    Map.new(model_ids, fn model_id -> {model_id, get(model_id)} end)
  end
end
