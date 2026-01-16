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
    result =
      config
      |> changeset(attrs)
      |> Repo.update()

    if match?({:ok, _}, result), do: Cache.delete_all()

    result
  end

  def change_config(config, attrs \\ %{}) do
    changeset(config, attrs)
  end

  defp changeset(config, attrs) do
    config
    |> cast(attrs, @fields)
    |> validate_required(@fields)
  end
end
