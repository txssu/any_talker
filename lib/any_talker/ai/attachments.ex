defmodule AnyTalker.AI.Attachments do
  @moduledoc false

  alias AnyTalker.AI.Message.Input
  alias AnyTalker.AI.Message.Output

  def download_message_image(nil), do: {:ok, nil}

  def download_message_image(%Input{} = message) do
    with {:ok, new_url} <- get_data(message.image_url),
         {:ok, reply} <- download_message_image(message.reply) do
      final_message = %{message | image_url: new_url, reply: reply}
      {:ok, final_message}
    end
  end

  def download_message_image(%Output{} = message), do: {:ok, message}

  defp get_data(nil), do: {:ok, nil}

  defp get_data(url) do
    with {:ok, env} <- Tesla.get(url) do
      encoded_data = Base.encode64(env.body)
      {:ok, "data:image/jpeg;base64,#{encoded_data}"}
    end
  end
end
