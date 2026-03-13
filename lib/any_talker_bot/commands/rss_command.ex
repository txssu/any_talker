defmodule AnyTalkerBot.RssCommand do
  @moduledoc false

  use AnyTalkerBot, :command

  alias AnyTalker.Accounts
  alias AnyTalker.AI.Summarizer
  alias AnyTalker.CommandParser
  alias AnyTalker.CommandParser.Arg
  alias AnyTalker.CommandParser.Command
  alias AnyTalker.RSS
  alias AnyTalkerBot.Reply
  alias ExGram.Model.Message

  require Logger

  @no_preview %ExGram.Model.LinkPreviewOptions{is_disabled: true}
  @summary_content_limit 500

  @spec_root %Command{
    name: :rss,
    labels: [],
    args: [],
    subcommands: [
      %Command{
        name: :news,
        labels: ["news", "новости"],
        args: [%Arg{name: :group, required: false}],
        subcommands: []
      },
      %Command{
        name: :add,
        labels: ["add", "добавить"],
        args: [%Arg{name: :url, required: true}, %Arg{name: :group, required: false}],
        subcommands: []
      },
      %Command{
        name: :remove,
        labels: ["remove", "удалить"],
        args: [%Arg{name: :url, required: true}],
        subcommands: []
      },
      %Command{
        name: :list,
        labels: ["list", "список"],
        args: [%Arg{name: :group, required: false}],
        subcommands: []
      },
      %Command{
        name: :summary,
        labels: ["summary", "сводка"],
        args: [%Arg{name: :group, required: false}],
        subcommands: []
      },
      %Command{
        name: :read,
        labels: ["read", "прочитать"],
        args: [%Arg{name: :group, required: false}],
        subcommands: []
      },
      %Command{
        name: :group,
        labels: ["group", "группа"],
        args: [],
        subcommands: [
          %Command{
            name: :new,
            labels: ["new", "новая"],
            args: [%Arg{name: :name, required: true}],
            subcommands: []
          },
          %Command{
            name: :delete,
            labels: ["delete", "удалить"],
            args: [%Arg{name: :name, required: true}],
            subcommands: []
          }
        ]
      }
    ]
  }

  @impl AnyTalkerBot.Command
  def call(%Reply{} = reply) do
    if reply.context.extra.is_group do
      Reply.halt(reply)
    else
      %Message{} = message = Reply.message(reply)
      user = reply.context.extra.user
      input = extract_input(message.text)
      result = handle_input(input, user.id)
      dispatch(reply, user, result)
    end
  end

  defp dispatch(reply, _user, {:show_groups, groups}) do
    Reply.send_message(reply, format_groups(groups))
  end

  defp dispatch(reply, user, {:news, group_name, group_id}) do
    send_news_page(reply, user.id, group_id, group_name, 0)
  end

  defp dispatch(reply, _user, {:list, feeds, group_name}) do
    Reply.send_message(reply, format_feeds(feeds, group_name), link_preview_options: @no_preview)
  end

  defp dispatch(reply, user, {:summary, articles, group_name, group_id}) do
    user_with_sub = Accounts.preload_current_subscription(user)

    if is_nil(user_with_sub.current_subscription) do
      Reply.send_message(reply, "Сводка доступна только для PRO-подписчиков.")
    else
      handle_summary(reply, user.id, articles, group_name, group_id)
    end
  end

  defp dispatch(reply, _user, {:ok, :marked_read, nil}),
    do: Reply.send_message(reply, "Отметил все статьи как прочитанные.")

  defp dispatch(reply, _user, {:ok, :marked_read, group_name}),
    do: Reply.send_message(reply, "Отметил все статьи в группе «#{group_name}» как прочитанные.")

  defp dispatch(reply, _user, {:ok, :subscribed, url, group_name}) do
    Reply.send_message(reply, "Подписался на #{url} в группе «#{group_name}».")
  end

  defp dispatch(reply, _user, {:ok, :unsubscribed, url}) do
    Reply.send_message(reply, "Отписался от #{url}.")
  end

  defp dispatch(reply, _user, {:ok, :group_created, name}) do
    Reply.send_message(reply, "Создал группу «#{name}».")
  end

  defp dispatch(reply, _user, {:ok, :group_deleted, name}) do
    Reply.send_message(reply, "Удалил группу «#{name}».")
  end

  defp dispatch(reply, _user, {:error, :group_not_found}) do
    Reply.send_message(reply, "Группа не найдена.")
  end

  defp dispatch(reply, _user, {:error, :fetch_failed}) do
    Reply.send_message(reply, "Не удалось загрузить фид. Проверь URL и попробуй снова.")
  end

  defp dispatch(reply, _user, {:error, :group_already_exists}) do
    Reply.send_message(reply, "Группа с таким именем уже существует.")
  end

  defp dispatch(reply, _user, {:error, :already_subscribed}) do
    Reply.send_message(reply, "Ты уже подписан на этот фид.")
  end

  defp dispatch(reply, _user, {:error, :not_found, suggestions}) do
    Reply.send_message(reply, not_found_text(suggestions))
  end

  defp dispatch(reply, _user, {:error, :ambiguous, options}) do
    Reply.send_message(reply, ambiguous_text(options))
  end

  defp dispatch(reply, _user, {:error, :missing_arg, arg}) do
    Reply.send_message(reply, missing_arg_text(arg))
  end

  @doc """
  Parses input and returns a result tuple. Called by `call/1` and directly in tests.

  ## Examples

      iex> handle_input("news Tech", user_id)
      {:news, "Tech", 42}

      iex> handle_input("", user_id)
      {:show_groups, [{%Group{}, 0}]}

  """
  def handle_input(input, user_id) do
    case CommandParser.parse(input, @spec_root) do
      {:error, :empty} -> {:show_groups, RSS.list_groups(user_id)}
      {:ok, result} -> execute(result, user_id)
      error -> error
    end
  end

  defp execute(%{command: :news, args: args}, user_id) do
    group_name = args[:group]

    case get_group_id(user_id, group_name) do
      {:ok, group_id} -> {:news, group_name, group_id}
      {:error, reason} -> {:error, reason}
    end
  end

  defp execute(%{command: :add, args: %{url: url} = args}, user_id) do
    group_name = args[:group]

    with {:ok, group} <- resolve_group(user_id, group_name),
         {:ok, _sub} <- RSS.subscribe(user_id, url, group.id) do
      {:ok, :subscribed, url, group.name}
    end
  end

  defp execute(%{command: :remove, args: %{url: url}}, user_id) do
    RSS.unsubscribe(user_id, url)
    {:ok, :unsubscribed, url}
  end

  defp execute(%{command: :list, args: args}, user_id) do
    group_name = args[:group]

    case resolve_group(user_id, group_name) do
      {:ok, group} -> {:list, RSS.list_feeds(user_id, group.id), group.name}
      {:error, reason} -> {:error, reason}
    end
  end

  defp execute(%{command: :summary, args: args}, user_id) do
    group_name = args[:group]

    case get_group_id(user_id, group_name) do
      {:ok, group_id} -> {:summary, fetch_unread(user_id, group_name), group_name, group_id}
      {:error, reason} -> {:error, reason}
    end
  end

  defp execute(%{command: :read, args: args}, user_id) do
    group_name = args[:group]

    case get_group_id(user_id, group_name) do
      {:ok, group_id} ->
        RSS.mark_all_read(user_id, group_id)
        {:ok, :marked_read, group_name}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp execute(%{command: :new, path: [:group, :new], args: %{name: name}}, user_id) do
    case RSS.create_group(user_id, name) do
      {:ok, _group} -> {:ok, :group_created, name}
      {:error, _changeset} -> {:error, :group_already_exists}
    end
  end

  defp execute(%{command: :delete, path: [:group, :delete], args: %{name: name}}, user_id) do
    case RSS.get_group_by_name(user_id, name) do
      nil -> {:error, :group_not_found}
      group -> delete_group_result(user_id, group, name)
    end
  end

  defp delete_group_result(user_id, group, name) do
    RSS.delete_group(user_id, group.id)
    {:ok, :group_deleted, name}
  end

  defp handle_summary(reply, _user_id, [], group_name, _group_id) do
    Reply.send_message(reply, no_news_text(group_name))
  end

  defp handle_summary(reply, _user_id, articles, group_name, group_id) do
    text = build_summary_text(articles)

    system_prompt = """
    Сделай краткую сводку следующих новостных статей на русском языке.
    Выдели ключевые факты, сгруппируй по темам если нужно. Будь лаконичен.
    Форматирование — только Telegram HTML: <b>жирный</b>, <i>курсив</i>, • для списков.
    Отвечай только сводкой, без вступлений.
    """

    case Summarizer.summarize(text, prompt: system_prompt) do
      {:ok, summary} ->
        header = if group_name, do: "Сводка по группе «#{group_name}»:\n\n", else: "Сводка новостей:\n\n"
        kb = AnyTalkerBot.RssFormatter.mark_read_keyboard(group_id)
        Reply.send_message(reply, header <> summary, mode: :html, reply_markup: kb, link_preview_options: @no_preview)

      {:error, reason} ->
        Logger.error("RSS summary generation failed: #{inspect(reason)}")
        Reply.send_message(reply, "Не удалось сформировать сводку.")
    end
  end

  defp send_news_page(reply, user_id, group_id, group_name, page) do
    {articles, total} = RSS.list_articles(user_id, group_id, page)

    if total == 0 do
      Reply.send_message(reply, no_news_text(group_name))
    else
      {text, keyboard} = AnyTalkerBot.RssFormatter.format_news_page(articles, page, total, group_id)
      Reply.send_message(reply, text, mode: :html, reply_markup: keyboard, link_preview_options: @no_preview)
    end
  end

  defp build_summary_text(articles) do
    Enum.map_join(articles, "\n\n", fn article ->
      content =
        article.content
        |> to_string()
        |> String.slice(0, @summary_content_limit)

      "## #{article.title}\n#{content}"
    end)
  end

  defp extract_input(text) do
    text
    |> String.trim()
    |> String.replace_prefix("/rss", "")
    |> String.trim()
  end

  defp fetch_unread(user_id, nil), do: RSS.list_unread_all(user_id)

  defp fetch_unread(user_id, group_name) do
    case RSS.get_group_by_name(user_id, group_name) do
      nil -> []
      group -> RSS.list_unread(user_id, group.id)
    end
  end

  defp resolve_group(user_id, nil), do: RSS.get_or_create_default_group(user_id)

  defp resolve_group(user_id, name) do
    case RSS.get_group_by_name(user_id, name) do
      nil -> {:error, :group_not_found}
      group -> {:ok, group}
    end
  end

  defp get_group_id(_user_id, nil), do: {:ok, nil}

  defp get_group_id(user_id, name) do
    case RSS.get_group_by_name(user_id, name) do
      nil -> {:error, :group_not_found}
      group -> {:ok, group.id}
    end
  end

  @help_text """


  Команды:
  /rss news [группа] — статьи (все)
  /rss read [группа] — отметить всё прочитанным
  /rss add <url> [группа] — подписаться
  /rss remove <url> — отписаться
  /rss list [группа] — список фидов
  /rss group new <название> — создать группу
  /rss group delete <название> — удалить группу
  /rss summary [группа] — сводка (PRO)\
  """

  defp format_groups([]) do
    "У тебя нет групп." <> @help_text
  end

  defp format_groups(groups) do
    lines =
      Enum.map_join(groups, "\n", fn {group, count} ->
        unread = if count > 0, do: " (#{count} новых)", else: ""
        "• #{group.name}#{unread}"
      end)

    "Твои группы:\n\n#{lines}" <> @help_text
  end

  defp format_feeds([], group_name), do: "В группе «#{group_name}» нет фидов."

  defp format_feeds(feeds, group_name) do
    lines = Enum.map_join(feeds, "\n", &format_feed/1)
    "Фиды в группе «#{group_name}»:\n\n#{lines}"
  end

  defp format_feed(feed) do
    marker = if feed.last_error_at, do: " ⚠️", else: ""
    "• #{feed.url}#{marker}"
  end

  defp no_news_text(nil), do: "Нет новых статей."
  defp no_news_text(group), do: "Нет новых статей в группе «#{group}»."

  defp not_found_text([]), do: "Неизвестная команда. Попробуй /rss без аргументов."

  defp not_found_text(suggestions) do
    "Неизвестная команда. Похожие: #{Enum.join(suggestions, ", ")}"
  end

  defp ambiguous_text(options) do
    "Неоднозначная команда. Ты имел в виду: #{Enum.join(options, ", ")}?"
  end

  defp missing_arg_text(:url), do: "Укажи URL фида."
  defp missing_arg_text(:name), do: "Укажи название группы."
  defp missing_arg_text(_arg), do: "Не хватает аргумента."
end
