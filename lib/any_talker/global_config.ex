defmodule AnyTalker.GlobalConfig do
  @moduledoc false
  use Ecto.Schema
  use Nebulex.Caching

  alias AnyTalker.Cache
  alias AnyTalker.Repo

  @type t :: %__MODULE__{}

  @fields ~w[ask_model ask_rate_limit ask_rate_limit_scale_ms ask_default_prompt]a

  schema "global_config" do
    field :ask_model, :string
    field :ask_rate_limit, :integer
    field :ask_rate_limit_scale_ms, :integer
    field :ask_default_prompt, :string
  end

  @spec get(term()) :: term()
  def get(key) when key in @fields do
    Map.fetch!(get(), key)
  end

  @decorate cacheable(cache: Cache)
  defp get do
    Repo.get!(__MODULE__, 1)
  end
end
