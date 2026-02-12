defmodule AnyTalker.AI.OpenRouter.Endpoints.Model do
  @moduledoc """
  OpenRouter model information.

  | Field Name   | Type    | Description                              |
  | ------------ | ------- | ---------------------------------------- |
  | id           | String  | Model identifier (e.g. openai/gpt-4)    |
  | name         | String  | Human-readable model name                |
  | created      | integer | Unix timestamp of creation               |
  | description  | String  | Model description                        |
  | architecture | map            | Model architecture details               |
  | endpoints    | List(Endpoint) | Available provider endpoints              |
  """

  alias AnyTalker.AI.OpenRouter.Endpoints.Endpoint

  defstruct [:id, :name, :created, :description, :architecture, endpoints: []]

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          created: integer(),
          description: String.t(),
          architecture: map(),
          endpoints: [Endpoint.t()]
        }
end
