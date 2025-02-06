defmodule JokerCynic.AI.Message do
  @moduledoc false
  use TypedStruct

  @type role :: :assistant | :system | :user

  typedstruct do
    field :role, role()
    field :username, String.t() | nil
    field :text, String.t()
  end

  @spec new_from_assistant(String.t()) :: t()
  def new_from_assistant(text), do: %__MODULE__{role: :assistant, text: text}

  @spec new_from_system(String.t()) :: t()
  def new_from_system(text), do: %__MODULE__{role: :system, text: text}

  @spec new_from_user(String.t(), String.t()) :: t()
  def new_from_user(username, text), do: %__MODULE__{role: :user, username: username, text: text}

  @spec format_list([t()]) :: [%{role: role, content: String.t()}]
  def format_list(messages) when is_list(messages) do
    messages
    |> Enum.flat_map(fn message ->
      case message.role do
        :user ->
          [
            %{role: message.role, content: message.text},
            %{role: :system, content: username_message_content(message)}
          ]

        _other ->
          [%{role: message.role, content: message.text}]
      end
    end)
    |> Enum.reverse()
  end

  defp username_message_content(message) do
    ~s(Username of following message author:\n"""\n#{message.username}\n""")
  end
end
