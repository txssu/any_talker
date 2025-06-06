defmodule AnyTalker.GlobalConfig do
  @moduledoc false
  use Ecto.Schema
  use Nebulex.Caching

  import Ecto.Changeset

  alias AnyTalker.Cache
  alias AnyTalker.Repo

  @type t :: %__MODULE__{}

  @fields ~w[ask_model ask_rate_limit ask_rate_limit_scale_ms ask_prompt]a

  schema "global_config" do
    field :ask_model, :string
    field :ask_rate_limit, :integer
    field :ask_rate_limit_scale_ms, :integer
    field :ask_prompt, :string
  end

  @spec get(term()) :: term()
  def get(key) when key in @fields do
    Map.fetch!(get_config(), key)
  end

  @spec get_config() :: t()
  @decorate cacheable(cache: Cache)
  def get_config do
    Repo.get!(__MODULE__, 1)
  end

  @spec update_config(t(), map()) :: {:ok, t()} | {:error, Changeset.t()}
  def update_config(config, attrs) do
    result =
      config
      |> changeset(attrs)
      |> Repo.update()

    if match?({:ok, _}, result), do: Cache.delete_all()

    result
  end

  @spec change_config(t(), map()) :: Changeset.t()
  def change_config(config, attrs \\ %{}) do
    changeset(config, attrs)
  end

  defp changeset(config, attrs) do
    config
    |> cast(attrs, @fields)
    |> validate_required([:ask_model, :ask_rate_limit, :ask_rate_limit_scale_ms])
  end
end
