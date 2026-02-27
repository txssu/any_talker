defmodule AnyTalker.Settings.ChatConfigTest do
  use AnyTalker.DataCase, async: true

  alias AnyTalker.Settings.ChatConfig

  describe "changeset/2" do
    test "casts antispam_captcha, antispam_via, antispam_keywords_enabled" do
      attrs = %{
        antispam_captcha: true,
        antispam_via: false,
        antispam_keywords_enabled: true
      }

      changeset = ChatConfig.changeset(%ChatConfig{}, attrs)

      assert changeset.valid?
      assert get_field(changeset, :antispam_captcha) == true
      assert get_field(changeset, :antispam_via) == false
      assert get_field(changeset, :antispam_keywords_enabled) == true
    end

    test "antispam field no longer exists" do
      refute Map.has_key?(%ChatConfig{}, :antispam)
    end
  end
end
