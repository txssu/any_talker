defmodule AnyTalkerBot.AntispamMiddlewareTest do
  use AnyTalker.DataCase, async: true
  use Repatch.ExUnit

  import AnyTalkerBot.BotFixtures

  alias AnyTalkerBot.AntispamMiddleware
  alias ExGram.Model.User

  @dickgrower_bot_id 6_465_471_545

  defp antispam_chat(overrides) do
    Map.merge(
      %{
        antispam_captcha: false,
        antispam_via: false,
        antispam_keywords_enabled: false,
        antispam_keywords: nil
      },
      overrides
    )
  end

  defp cnt_with_chat(msg, antispam_chat) do
    [message: msg]
    |> context()
    |> Map.update!(:extra, &Map.put(&1, :chat, antispam_chat))
    |> Map.put(:bot_info, %User{id: 999, is_bot: true, first_name: "Bot"})
  end

  describe "antispam_via toggle" do
    test "deletes via-bot message when antispam_via is true" do
      Repatch.patch(ExGram, :delete_message, fn _chat_id, _msg_id, _opts -> :ok end)

      msg = message(%{via_bot: %User{id: @dickgrower_bot_id}})
      cnt = cnt_with_chat(msg, antispam_chat(%{antispam_via: true}))

      AntispamMiddleware.call(cnt, [])

      assert Repatch.called?(ExGram, :delete_message, 3)
    end

    test "passes through via-bot message when antispam_via is false" do
      Repatch.patch(ExGram, :delete_message, fn _chat_id, _msg_id, _opts -> :ok end)

      msg = message(%{via_bot: %User{id: @dickgrower_bot_id}})
      cnt = cnt_with_chat(msg, antispam_chat(%{antispam_via: false}))

      result = AntispamMiddleware.call(cnt, [])

      refute Repatch.called?(ExGram, :delete_message, 3)
      assert result == cnt
    end
  end

  describe "antispam_keywords_enabled toggle" do
    test "deletes message matching keyword when antispam_keywords_enabled is true" do
      Repatch.patch(ExGram, :delete_message, fn _chat_id, _msg_id, _opts -> :ok end)

      msg = message(%{text: "buy cheap meds here"})
      cnt = cnt_with_chat(msg, antispam_chat(%{antispam_keywords_enabled: true, antispam_keywords: "meds spam"}))

      AntispamMiddleware.call(cnt, [])

      assert Repatch.called?(ExGram, :delete_message, 3)
    end

    test "passes through message with keyword when antispam_keywords_enabled is false" do
      Repatch.patch(ExGram, :delete_message, fn _chat_id, _msg_id, _opts -> :ok end)

      msg = message(%{text: "buy cheap meds here"})
      cnt = cnt_with_chat(msg, antispam_chat(%{antispam_keywords_enabled: false, antispam_keywords: "meds"}))

      result = AntispamMiddleware.call(cnt, [])

      refute Repatch.called?(ExGram, :delete_message, 3)
      assert result == cnt
    end
  end

  describe "antispam_captcha toggle" do
    test "passes through new_chat_members event when antispam_captcha is false" do
      new_member = %User{id: 111, is_bot: false, first_name: "Newcomer"}
      msg = message(%{new_chat_members: [new_member]})
      cnt = cnt_with_chat(msg, antispam_chat(%{antispam_captcha: false}))

      result = AntispamMiddleware.call(cnt, [])

      assert result == cnt
    end

    test "creates captcha and halts when antispam_captcha is true and new member joins" do
      Repatch.patch(AnyTalker.Antispam, :create_captcha, fn _uid, _name, _chat_id, _msg_id -> :ok end)

      new_member = %User{id: 111, is_bot: false, first_name: "Newcomer"}
      msg = message(%{new_chat_members: [new_member]})
      cnt = cnt_with_chat(msg, antispam_chat(%{antispam_captcha: true}))

      result = AntispamMiddleware.call(cnt, [])

      assert Repatch.called?(AnyTalker.Antispam, :create_captcha, 4)
      assert result.middleware_halted == true
    end
  end

  describe "left_chat_member with no captcha" do
    test "does not crash when left member has no captcha record" do
      member = %User{id: 222, is_bot: false, first_name: "Leaving"}
      msg = message(%{left_chat_member: member})
      cnt = cnt_with_chat(msg, antispam_chat(%{antispam_captcha: true}))

      # Should not raise - member left without ever having a captcha
      result = AntispamMiddleware.call(cnt, [])

      assert result.middleware_halted == true
    end
  end

  describe "captcha resolution with non-text message" do
    test "does not process captcha when message has no text" do
      # message.text is nil (e.g. a photo) — should NOT ban the user
      msg = message(%{text: nil})
      cnt = cnt_with_chat(msg, antispam_chat(%{antispam_captcha: true}))

      result = AntispamMiddleware.call(cnt, [])

      assert result == cnt
    end
  end

  describe "nil chat" do
    test "passes through when chat is nil" do
      msg = message(%{text: "hello"})

      cnt =
        [message: msg]
        |> context()
        |> Map.update!(:extra, &Map.put(&1, :chat, nil))

      result = AntispamMiddleware.call(cnt, [])

      assert result == cnt
    end
  end
end
