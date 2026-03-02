defmodule AnyTalker.GlobalConfig do
  @moduledoc false
  use Ecto.Schema
  use Nebulex.Caching

  import Ecto.Changeset

  alias AnyTalker.Cache
  alias AnyTalker.Repo

  @type t :: %__MODULE__{}

  @fields ~w[ask_model ask_max_tokens ask_refill_interval_ms ask_refill_amount ask_prompt timezone]a

  schema "global_config" do
    field :ask_model, :string
    field :ask_max_tokens, :integer
    field :ask_refill_interval_ms, :integer
    field :ask_refill_amount, :integer
    field :ask_prompt, :string
    field :timezone, :string
  end

  def get(key) when key in @fields do
    Map.fetch!(get_config(), key)
  end

  @decorate cacheable(cache: Cache)
  def get_config do
    Repo.get!(__MODULE__, 1)
  end

  def update_config(config, attrs) do
    config
    |> changeset(attrs)
    |> Repo.update()
    |> maybe_clear_cache()
  end

  def change_config(config, attrs \\ %{}) do
    changeset(config, attrs)
  end

  def change_general(config, attrs \\ %{}) do
    config
    |> cast(attrs, [:timezone])
    |> validate_required([:timezone])
  end

  def update_general(config, attrs) do
    config
    |> change_general(attrs)
    |> Repo.update()
    |> maybe_clear_cache()
  end

  def change_ask_model(config, attrs \\ %{}) do
    cast(config, attrs, [:ask_model, :ask_prompt])
  end

  def update_ask_model(config, attrs) do
    config
    |> change_ask_model(attrs)
    |> Repo.update()
    |> maybe_clear_cache()
  end

  def change_ask_limits(config, attrs \\ %{}) do
    config
    |> cast(attrs, [:ask_max_tokens, :ask_refill_interval_ms, :ask_refill_amount])
    |> validate_required([:ask_max_tokens, :ask_refill_interval_ms, :ask_refill_amount])
  end

  def update_ask_limits(config, attrs) do
    config
    |> change_ask_limits(attrs)
    |> Repo.update()
    |> maybe_clear_cache()
  end

  defp maybe_clear_cache({:ok, _config} = result) do
    Cache.delete_all()
    result
  end

  defp maybe_clear_cache(result), do: result

  defp changeset(config, attrs) do
    config
    |> cast(attrs, @fields)
    |> validate_required(@fields)
  end
end
