defmodule AnyTalker.Settings do
  @moduledoc false
  alias AnyTalker.Repo
  alias AnyTalker.Settings.ChatConfig

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

  @spec update_chat_config(ChatConfig.t(), map()) :: {:ok, ChatConfig.t()} | {:error, Ecto.Changeset.t()}
  def update_chat_config(chat_config, attrs) do
    chat_config
    |> ChatConfig.changeset(attrs)
    |> Repo.update()
  end

  @spec change_chat_config(ChatConfig.t(), map()) :: Ecto.Changeset.t()
  def change_chat_config(chat_config, attrs \\ %{}) do
    ChatConfig.changeset(chat_config, attrs)
  end
end
