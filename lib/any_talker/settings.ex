defmodule AnyTalker.Settings do
  @moduledoc false
  alias AnyTalker.GlobalConfig
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

  @spec get_full_chat_config(integer() | nil) :: ChatConfig.t()
  def get_full_chat_config(nil), do: merge_configs(%ChatConfig{}, GlobalConfig.get_config())

  def get_full_chat_config(id) do
    id
    |> get_chat_config()
    |> merge_configs(GlobalConfig.get_config())
  end

  defp merge_configs(chat, global) do
    %{
      chat
      | ask_model: chat.ask_model || global.ask_model,
        ask_rate_limit: chat.ask_rate_limit || global.ask_rate_limit,
        ask_rate_limit_scale_ms: chat.ask_rate_limit_scale_ms || global.ask_rate_limit_scale_ms,
        ask_prompt: chat.ask_prompt || global.ask_prompt
    }
  end
end
