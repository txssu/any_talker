defmodule JokerCynic.Settings do
  @moduledoc false
  alias JokerCynic.Repo
  alias JokerCynic.Settings.ChatConfig

  @spec get_chat_config(integer()) :: ChatConfig.t()
  def get_chat_config(id) do
    Repo.get(ChatConfig, id) || %ChatConfig{}
  end

  @spec upsert_chat_config(integer(), map()) :: {:ok, ChatConfig.t()}
  def upsert_chat_config(id, title) do
    Repo.insert(%ChatConfig{id: id, title: title},
      on_conflict: {:replace, [:title]},
      conflict_target: [:id]
    )
  end
end
