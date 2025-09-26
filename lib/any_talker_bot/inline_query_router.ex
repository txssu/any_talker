defmodule AnyTalkerBot.InlineQueryRouter do
  @moduledoc """
  Routes inline queries to appropriate command handlers based on command prefixes.
  """

  alias AnyTalkerBot.CurrencyCommand

  @commands [
    CurrencyCommand
  ]

  def route_inline_query(%{context: %{update: %{inline_query: query}}} = reply) do
    query_text = String.trim(query.query)

    case find_command(query_text) do
      {:ok, command_module} -> command_module.handle_inline_query(reply)
      {:error, :no_command} -> send_help_message(reply, query)
    end
  end

  defp find_command(""), do: {:error, :no_command}

  defp find_command(query_text) do
    first_word =
      query_text
      |> String.split(" ", trim: true)
      |> List.first()
      |> to_string()

    Enum.find_value(@commands, {:error, :no_command}, fn command_module ->
      prefixes = command_module.command_prefixes()

      if first_word in prefixes do
        {:ok, command_module}
      end
    end)
  end

  defp send_help_message(reply, query) do
    help_text = build_help_text()

    result = %ExGram.Model.InlineQueryResultArticle{
      type: "article",
      id: "inline_help",
      title: help_text,
      input_message_content: %ExGram.Model.InputTextMessageContent{
        message_text: help_text
      }
    }

    ExGram.answer_inline_query(query.id, [result], bot: AnyTalkerBot.Dispatcher.bot())
    %{reply | halt: true}
  end

  defp build_help_text do
    commands_help =
      Enum.map_join(@commands, "\n", fn command_module ->
        prefixes = Enum.join(command_module.command_prefixes(), ", ")
        description = command_module.command_description()
        "• #{prefixes} - #{description}"
      end)

    """
    Доступные inline команды:

    #{commands_help}
    """
  end
end
