defmodule JokerCynic.Events.Update do
  @moduledoc false
  use Ecto.Schema

  @type t() :: %__MODULE__{}

  schema "updates" do
    field :value, :map

    timestamps(type: :utc_datetime)
  end
end
