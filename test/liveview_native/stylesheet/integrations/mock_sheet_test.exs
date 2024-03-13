defmodule MockSheetTest do
  use ExUnit.Case

  describe "stylesheet output" do
    test "will compile the stylesheet into an asset file" do
      {styles, _} =
        File.read!("priv/static/assets/mock_sheet.mock.styles")
        |> Code.eval_string()

      assert styles["color-blue"] == ["rule-2"]
      assert styles["color-number-3"] == ["rule-1", "rule-23"]
      assert styles["custom-123-456"] == ["rule-123", "rule-456"]
    end
  end
end
