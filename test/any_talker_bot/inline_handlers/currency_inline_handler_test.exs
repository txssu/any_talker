defmodule AnyTalkerBot.InlineHandlers.CurrencyInlineHandlerTest do
  use ExUnit.Case, async: true
  use Repatch.ExUnit

  import AnyTalkerBot.BotFixtures

  alias AnyTalker.Currency.Client
  alias AnyTalkerBot.InlineHandlers.CurrencyInlineHandler
  alias ExGram.Model.InlineQuery

  describe "match?/1" do
    test "matches three words with numeric amount" do
      assert CurrencyInlineHandler.match?("usd rub 100")
    end

    test "matches with k shortcut" do
      assert CurrencyInlineHandler.match?("usd rub 10k")
    end

    test "matches with kk shortcut" do
      assert CurrencyInlineHandler.match?("usd rub 5kk")
    end

    test "matches with float amount" do
      assert CurrencyInlineHandler.match?("usd rub 99.5")
    end

    test "does not match two words" do
      refute CurrencyInlineHandler.match?("usd rub")
    end

    test "does not match four words" do
      refute CurrencyInlineHandler.match?("usd rub 100 extra")
    end

    test "does not match non-numeric third word" do
      refute CurrencyInlineHandler.match?("usd rub notanumber")
    end

    test "does not match zero amount" do
      refute CurrencyInlineHandler.match?("usd rub 0")
    end

    test "does not match amount over 1 billion" do
      refute CurrencyInlineHandler.match?("usd rub 2000000000")
    end
  end

  describe "build_results/1" do
    test "returns conversion result on success" do
      Repatch.patch(Client, :get_currencies, fn "usd" ->
        {:ok, %{"rub" => 90.0}}
      end)

      query = inline_query("usd rub 100")

      assert [result] = CurrencyInlineHandler.build_results(query)
      assert result.id == "currency_conversion"
      assert result.title == "USD → RUB"
    end

    test "returns error result when target currency not found" do
      Repatch.patch(Client, :get_currencies, fn "usd" ->
        {:ok, %{"eur" => 0.9}}
      end)

      query = inline_query("usd xxx 100")

      assert [result] = CurrencyInlineHandler.build_results(query)
      assert result.id == "currency_error"
      assert result.description =~ "не найдена"
    end

    test "returns error result when source currency not found" do
      Repatch.patch(Client, :get_currencies, fn "zzz" ->
        {:error, :not_found}
      end)

      query = inline_query("zzz rub 100")

      assert [result] = CurrencyInlineHandler.build_results(query)
      assert result.id == "currency_error"
      assert result.description =~ "не найдена"
    end

    test "returns error result on API failure" do
      Repatch.patch(Client, :get_currencies, fn _from ->
        {:error, :timeout}
      end)

      query = inline_query("usd rub 100")

      assert [result] = CurrencyInlineHandler.build_results(query)
      assert result.id == "currency_error"
      assert result.description =~ "Ошибка"
    end
  end

  defp inline_query(text) do
    %InlineQuery{id: "q1", from: user(), query: text, offset: ""}
  end
end
