defmodule JokerCynic.Events do
  @moduledoc false

  alias JokerCynic.ChRepo
  alias JokerCynic.Events.Message

  @spec save_message(map()) :: :ok
  def save_message(message) do
    attrs = %{
      message_id: message.message_id,
      date: message.date,
      text: message.text,
      from_id: message.from.id,
      from_username: message.from.username,
      from_first_name: message.from.first_name,
      chat_id: message.chat.id,
      chat_title: message.chat.title
    }

    %Message{}
    |> Ecto.Changeset.change(attrs)
    |> ChRepo.insert()

    :ok
  end
end
