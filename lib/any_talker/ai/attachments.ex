defmodule AnyTalker.AI.Attachments do
  @moduledoc false

  alias AnyTalker.AI.Message

  @spec download_message_image(maybe_message) :: {:ok, maybe_message} | {:error, any()}
        when maybe_message: Message.t() | nil
  def download_message_image(nil), do: {:ok, nil}

  def download_message_image(message) do
    with {:ok, new_url} <- get_data(message.image_url),
         {:ok, reply} <- download_message_image(message.reply) do
      final_message = %{message | image_url: new_url, reply: reply}
      {:ok, final_message}
    end
  end

  defp get_data(nil), do: {:ok, nil}

  defp get_data(url) do
    with {:ok, env} <- Tesla.get(url) do
      encoded_data = Base.encode64(env.body)
      {:ok, "data:image/jpeg;base64,#{encoded_data}"}
    end
  end
end
