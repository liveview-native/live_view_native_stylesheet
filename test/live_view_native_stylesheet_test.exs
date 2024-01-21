defmodule LiveViewNative.StylesheetTest do
  use ExUnit.Case
  doctest LiveViewNative.Stylesheet

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

  test "will compile the rules for all listed classes" do
    output = MockSheet.compile_ast(["color-blue", "color-yellow"], target: nil)

    assert output == %{"color-blue" => ["rule-2"], "color-yellow" => ["rule-yellow"]}
  end

  test "will compile the rules for a specific target" do
    output = MockSheet.compile_ast(["color-blue", "color-yellow"], target: :watch)

    assert output == %{"color-blue" => ["rule-5"], "color-yellow" => ["rule-yellow"]}
  end

  test "won't fail when an class name isn't found" do
    output = MockSheet.compile_ast(["foobar"], target: :watch)

    assert output == %{}
  end

  test "can compile without target, will default to `target: :all`" do
    output = MockSheet.compile_ast(["color-blue", "color-yellow"])

    assert output == %{"color-blue" => ["rule-2"], "color-yellow" => ["rule-yellow"]}
  end

  test "can compile for a single class name" do
    output = MockSheet.compile_ast("color-blue")

    assert output == %{"color-blue" => ["rule-2"]}
  end

  test "can compile custom classes using the RULES sigil" do
    output = MockSheet.compile_ast("custom-123-456")

    assert output == %{"custom-123-456" => ["rule-123", "rule-456"]}

    output = MockSheet.compile_ast("custom-789-123")
    assert output == %{"custom-789-123" => ["rule-789", "rule-123"]}
  end

  describe "LiveViewNative.Stylesheet sigil" do
    test "single rules supported" do
      output = MockSheet.compile_ast(["color-yellow"], target: :all)

      assert output == %{"color-yellow" => ["rule-yellow"]}
    end

    test "multiple rules and class name pattern matching" do
      output = MockSheet.compile_ast(["color-number-4"], target: :all)

      assert output == %{"color-number-4" => ["rule-1", "rule-24"]}
    end

    test "can convert the output to a string" do
      output = MockSheet.compile_string(["color-number-3"])

      assert output == ~s(%{"color-number-3" => ["rule-1", "rule-23"]})
    end
  end
end
