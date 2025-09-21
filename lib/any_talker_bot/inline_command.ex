defmodule AnyTalkerBot.InlineCommand do
  @moduledoc """
  Behaviour for inline query commands.

  ## Usage

      defmodule MyBot.WeatherCommand do
        use AnyTalkerBot, :inline_command

        @impl AnyTalkerBot.InlineCommand
        def handle_inline_query(reply) do
          # Process inline query and return reply
          reply
        end

        @impl AnyTalkerBot.InlineCommand
        def command_prefix, do: "weather"
      end

  """

  @type reply :: term()

  @callback handle_inline_query(reply) :: reply
  @callback command_prefixes() :: [String.t()]
  @callback command_description() :: String.t()
end
