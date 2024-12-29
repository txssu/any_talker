defmodule JokerCynic.Events.Update do
  @moduledoc false
  use Ecto.Schema

  schema "updates" do
    field :value, :map

    timestamps(type: :utc_datetime)
  end
end
