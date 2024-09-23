defmodule MockSheetTest do
  use ExUnit.Case

  describe "stylesheet output" do
    test "will compile the stylesheet into an asset file" do
      styles =
        File.read!("priv/static/assets/mock_sheet.styles")
        |> :json.decode()

      assert styles["color-blue"] == ["rule-2"]
      assert styles["color-number-3"] == ["rule-1", "rule-23"]
      assert styles["custom-123-456"] == ["rule-123", "rule-456"]
    end
  end

  describe "style parsing" do
    test "parses from elixir files containing ~LVN templates" do
      styles =
        File.read!("priv/static/assets/mock_sheet.styles")
        |> :json.decode()

      assert styles["c-string-1"] == ["c-string-1"]
      assert styles["c-string-2"] == ["c-string-2"]
      assert styles["c-string-3"] == ["c-string-3"]

      assert styles["c-bracket-1"] == ["c-bracket-1"]
      assert styles["c-bracket-\"2\""] == ["c-bracket-\"2\""]
      assert styles["c-bracket-3"] == ["c-bracket-3"]
      assert styles["c-bracket-4"] == ["c-bracket-4"]

      assert styles["c-slot-string-1"] == ["c-slot-string-1"]
      assert styles["c-local-component-string-1"] == ["c-local-component-string-1"]

      refute Map.has_key?(styles, "c-illegal")
    end

    test "parses from template files" do
      styles =
        File.read!("priv/static/assets/mock_sheet.styles")
        |> :json.decode()

      assert styles["t-string-1"] == ["t-string-1"]
      assert styles["t-string-2"] == ["t-string-2"]
      assert styles["t-string-3"] == ["t-string-3"]

      assert styles["t-bracket-1"] == ["t-bracket-1"]
      assert styles["t-bracket-\"2\""] == ["t-bracket-\"2\""]
      assert styles["t-bracket-3"] == ["t-bracket-3"]
      assert styles["t-bracket-4"] == ["t-bracket-4"]
      assert styles["t-bracket-5"] == ["t-bracket-5"]
      assert styles["t-bracket-6"] == ["t-bracket-6"]

      assert styles["t-slot-string-1"] == ["t-slot-string-1"]
      assert styles["t-local-component-string-1"] == ["t-local-component-string-1"]

      refute Map.has_key?(styles, "t-illegal")
    end

    test "parses from other file types defined in config" do
      styles =
        File.read!("priv/static/assets/mock_sheet.styles")
        |> :json.decode()

      assert styles["t-other-1"] == ["t-other-1"]
    end

    test "parses class and styles" do
      styles =
        File.read!("priv/static/assets/mock_sheet.styles")
        |> :json.decode()

      assert styles["c-class-1"] == ["c-rules-1"]
      assert styles["c-style-1"] == ["c-style-1"]

      assert styles["t-class-1"] == ["t-rules-1"]
      assert styles["t-style-1"] == ["t-style-1"]
    end
  end
end
