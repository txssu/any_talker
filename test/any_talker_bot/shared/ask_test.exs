defmodule AnyTalkerBot.Shared.AskTest do
  use ExUnit.Case, async: true

  alias AnyTalkerBot.Shared.Ask

  describe "replace_keywords/1" do
    test "replaces standalone 'не нужно'" do
      assert Ask.replace_keywords("это не нужно делать") == "это #ненужно делать"
    end

    test "does not replace 'не нужно' inside 'мне нужно'" do
      assert Ask.replace_keywords("мне нужно помочь") == "мне нужно помочь"
    end

    test "does not replace 'нужно' that is part of 'мне нужно' even with surrounding words" do
      assert Ask.replace_keywords("скажи мне нужно ли это") == "скажи мне нужно ли это"
    end

    test "replaces standalone 'достаточно'" do
      assert Ask.replace_keywords("этого достаточно") == "этого #достаточно"
    end

    test "does not alter '#достаточно' when it is part of a longer word" do
      # e.g. 'недостаточно' should not be replaced
      assert Ask.replace_keywords("этого недостаточно") == "этого недостаточно"
    end

    test "replaces 'не нужно' with multiple spaces" do
      assert Ask.replace_keywords("это не  нужно") == "это #ненужно"
    end

    test "replaces both keywords in the same text" do
      assert Ask.replace_keywords("этого достаточно, не нужно больше") ==
               "этого #достаточно, #ненужно больше"
    end
  end
end
