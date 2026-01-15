defprotocol AnyTalker.AI.Envelope.Source do
  @moduledoc """
  Protocol for converting various message sources into Envelope.
  """

  alias AnyTalker.AI.Envelope

  @doc """
  Converts the source object into an Envelope
  """
  @spec to_envelope(t, AnyTalker.AI.Envelope.Context.t()) :: Envelope.t()
  def to_envelope(source, context)
end

defimpl AnyTalker.AI.Envelope.Source, for: ExGram.Model.Message do
  alias AnyTalker.Accounts
  alias AnyTalker.AI.Envelope
  alias AnyTalker.AI.Envelope.AnonymousAuthor
  alias AnyTalker.AI.Envelope.Context
  alias AnyTalker.AI.Instruction
  alias AnyTalker.Settings.ChatConfig
  alias AnyTalker.TypedStructAccess
  alias ExGram.Model.Message
  alias ExGram.Model.MessageOriginHiddenUser
  alias ExGram.Model.MessageOriginUser
  alias ExGram.Model.PhotoSize
  alias ExGram.Model.TextQuote
  alias ExGram.Model.User

  require TypedStructAccess

  def to_envelope(%Message{} = message, %Context{} = context) do
    quote_text = TypedStructAccess.get(message.quote.text, [TextQuote])
    reply = build_reply(message.reply_to_message, context)

    from_id = TypedStructAccess.get(message.from.id, [User])

    is_bot? = from_id == context.bot_id

    role = if is_bot?, do: "assistant", else: "user"

    display_name = if not is_bot?, do: display_name_for(context.author || message.from)

    timezone = Accounts.get_timezone(context.author, context.chat)

    instructions =
      context.chat.ask_prompt
      |> TypedStructAccess.get([ChatConfig])
      |> Instruction.build(context.response_mode, timezone)

    model_string = TypedStructAccess.get(context.chat.ask_model, [ChatConfig]) || AnyTalker.GlobalConfig.get(:ask_model)
    models = String.split(model_string, " ", trim: true)

    %Envelope{
      message_id: message.message_id,
      role: role,
      username: display_name,
      text: message.text || message.caption,
      image_base64: download_photo(message),
      quote: quote_text,
      reply: reply,
      instructions: instructions,
      models: models,
      chat: context.chat,
      author: context.author,
      message: message
    }
  end

  defp download_photo(%Message{} = msg) do
    case get_image_url(msg) do
      nil ->
        nil

      url ->
        %Tesla.Env{body: body} = Tesla.get!(url)
        encoded_data = Base.encode64(body)
        "data:image/jpeg;base64,#{encoded_data}"
    end
  end

  defp get_image_url(%Message{photo: nil}), do: nil

  defp get_image_url(%Message{photo: photos}) do
    %PhotoSize{file_id: photo_id} = best_fit_photo(photos, 1536 * 1024)

    options = [bot: AnyTalkerBot.bot()]

    photo_id
    |> ExGram.get_file!(options)
    |> ExGram.File.file_url(options)
  end

  def best_fit_photo(sizes, max_area) when is_list(sizes) and is_integer(max_area) do
    fit_sizes =
      for %PhotoSize{width: w, height: h} = photo <- sizes,
          area = w * h,
          area < max_area do
        {photo, area}
      end

    {photo, _area} =
      Enum.max_by(
        fit_sizes,
        fn {_photo, area} -> area end,
        fn -> {nil, nil} end
      )

    photo
  end

  defp display_name_for(%Accounts.User{} = user) do
    Accounts.display_name(user)
  end

  defp display_name_for(%User{} = user) do
    user.id
    |> Accounts.get_user()
    |> Accounts.display_name()
  end

  defp display_name_for(%AnonymousAuthor{display_name: name}), do: name

  defp build_reply(nil, _context), do: nil

  defp build_reply(%Message{} = reply_message, %Context{} = context) do
    reply_author = get_reply_author(reply_message)
    reply_context = %{context | author: reply_author}

    AnyTalker.AI.Envelope.Source.to_envelope(reply_message, reply_context)
  end

  defp get_reply_author(%Message{} = message) do
    case message do
      %{forward_origin: %MessageOriginUser{sender_user: %User{id: id}}} ->
        Accounts.get_user(id)

      %{forward_origin: %MessageOriginHiddenUser{sender_user_name: name}} ->
        %AnonymousAuthor{display_name: name}

      %{from: %User{id: id}} ->
        Accounts.get_user(id)
    end
  end
end
