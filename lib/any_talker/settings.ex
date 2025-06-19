defmodule AnyTalker.Settings do
  @moduledoc false
  alias AnyTalker.GlobalConfig
  alias AnyTalker.Repo
  alias AnyTalker.Settings.ChatConfig
  alias AnyTalkerBot.Attachments

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

  @spec get_or_fetch_chat_avatar(integer()) :: {:ok, binary() | nil} | {:error, term()}
  def get_or_fetch_chat_avatar(chat_id) do
    chat_config = get_chat_config(chat_id)

    if should_fetch_avatar?(chat_config) do
      fetch_and_store_avatar(chat_id, chat_config)
    else
      {:ok, chat_config.avatar_blob}
    end
  end

  defp should_fetch_avatar?(%ChatConfig{avatar_updated_at: nil}), do: true

  defp should_fetch_avatar?(%ChatConfig{avatar_updated_at: updated_at}) do
    thirty_minutes_ago = DateTime.add(DateTime.utc_now(), -30, :minute)
    DateTime.before?(updated_at, thirty_minutes_ago)
  end

  defp fetch_and_store_avatar(chat_id, chat_config) do
    options = [bot: AnyTalkerBot.bot()]

    with {:ok, chat} <- ExGram.get_chat(chat_id, options),
         photo when not is_nil(photo) <- Map.get(chat, :photo),
         small_file_id when not is_nil(small_file_id) <- Map.get(photo, :small_file_id),
         file_url = Attachments.get_file_link(small_file_id),
         {:ok, %{body: avatar_data}} <- :get |> Finch.build(file_url) |> Finch.request(AnyTalker.Finch),
         {:ok, updated_config} <- update_avatar(chat_config, avatar_data) do
      {:ok, updated_config.avatar_blob}
    else
      error ->
        {:error, error}
    end
  end

  defp update_avatar(chat_config, avatar_data) do
    case chat_config.id do
      nil ->
        {:error, :no_chat_id}

      id ->
        Repo.insert(%ChatConfig{id: id, avatar_blob: avatar_data, avatar_updated_at: DateTime.utc_now(:second)},
          on_conflict: {:replace, [:avatar_blob, :avatar_updated_at]},
          conflict_target: [:id]
        )
    end
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
