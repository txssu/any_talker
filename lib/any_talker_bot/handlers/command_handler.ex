defmodule AnyTalkerBot.Handlers.CommandHandler do
  @moduledoc false

  alias AnyTalkerBot.Reply

  def execute(reply, {:command, :privacy, _msg}) do
    AnyTalkerBot.PrivacyCommand.call(reply)
  end

  def execute(reply, {:command, :ban, _msg}) do
    AnyTalkerBot.BanCommand.call(reply)
  end

  def execute(reply, {:command, :ask, _msg}) do
    AnyTalkerBot.TypingStatus.with_typing(&AnyTalkerBot.AskCommand.call(&1, :ask), reply)
  end

  def execute(reply, {:command, :ask_detailed, _msg}) do
    AnyTalkerBot.TypingStatus.with_typing(&AnyTalkerBot.AskCommand.call(&1, :ask_detailed), reply)
  end

  def execute(reply, {:command, :que_pro, _msg}) do
    AnyTalkerBot.ProInfoCommand.call(reply)
  end

  def execute(reply, {:command, :buy_pro, _msg}) do
    AnyTalkerBot.BuyProCommand.call(reply)
  end

  def execute(reply, {:command, :clean, _msg}) do
    AnyTalkerBot.CleanUrlCommand.call(reply)
  end

  def execute(reply, {:command, :rss, _msg}) do
    AnyTalkerBot.RssCommand.call(reply)
  end

  def execute(reply, {:command, _unknown, _msg}) do
    Reply.halt(reply)
  end
end
