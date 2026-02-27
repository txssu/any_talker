defmodule AnyTalkerBot.BotFixtures do
  @moduledoc """
  Fixtures for building ExGram structs in tests.

  ## Usage

      import AnyTalkerBot.BotFixtures

      {command, ctx} = command(:privacy)
      reply = Dispatcher.build_reply(command, ctx)
  """

  def user(attrs \\ %{}) do
    Map.merge(
      %ExGram.Model.User{id: non_owner_id(), is_bot: false, first_name: "Test"},
      attrs
    )
  end

  defp non_owner_id do
    id = System.unique_integer([:positive, :monotonic])
    if id == AnyTalkerBot.Config.owner_id(), do: non_owner_id(), else: id
  end

  def owner_user(attrs \\ %{}) do
    user(Map.merge(%{id: AnyTalkerBot.Config.owner_id()}, attrs))
  end

  def chat(attrs \\ %{}) do
    Map.merge(
      %ExGram.Model.Chat{id: System.unique_integer([:positive, :monotonic]), type: "private"},
      attrs
    )
  end

  def message(attrs \\ %{}) do
    defaults = %ExGram.Model.Message{
      message_id: System.unique_integer([:positive, :monotonic]),
      date: 0,
      chat: chat(),
      from: user()
    }

    Map.merge(defaults, attrs)
  end

  def command(name, msg \\ nil) do
    msg = msg || message()
    {{:command, name, msg}, context(message: msg)}
  end

  def context(attrs \\ []) do
    attrs = Map.new(attrs)
    msg = Map.get(attrs, :message, message())

    defaults = %ExGram.Cnt{
      update: %ExGram.Model.Update{update_id: System.unique_integer([:positive, :monotonic]), message: msg},
      extra: %{}
    }

    Map.merge(defaults, Map.delete(attrs, :message))
  end
end
