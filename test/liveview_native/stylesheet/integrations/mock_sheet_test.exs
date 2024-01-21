defmodule MockSheetTest do
  use ExUnit.Case

  describe "embed_stylesheet" do
    test "will generate stylesheet/1 with the correct styles" do
      {styles, _} =
        MockLayout.stylesheet(%{})
        |> Phoenix.LiveViewTest.rendered_to_string()
        |> Floki.parse_fragment!()
        |> Floki.find("style")
        |> Floki.text()
        |> Code.eval_string()

      assert styles["color-blue"] == ["rule-2"]
      assert styles["color-number-3"] == ["rule-1", "rule-23"]
      assert styles["custom-123-456"] == ["rule-123", "rule-456"]
    end
  end
end