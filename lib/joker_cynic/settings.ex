defmodule JokerCynic.Settings do
  @moduledoc false
  alias JokerCynic.Repo
  alias JokerCynic.Settings.ChatConfig

  def get_chat_config(id) do
    Repo.get(ChatConfig, id) || %ChatConfig{}
  end
end
