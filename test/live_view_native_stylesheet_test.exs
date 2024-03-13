defmodule LiveViewNative.StylesheetTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  doctest LiveViewNative.Stylesheet

  test "will compile the rules for all listed classes" do
    output = MockSheet.compile_ast(["color-blue", "color-yellow"])

    assert output == %{"color-blue" => ["rule-2"], "color-yellow" => ["rule-yellow"]}
  end

  test "won't fail when an class name isn't found" do
    output = MockSheet.compile_ast(["foobar"])

    assert output == %{}
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

  test "will capture and log any raises within `class/1` when compiling stylesheet" do
    assert capture_io(:user, fn ->
      assert MockSheet.compile_ast(["raise-12"]) == %{}
      Logger.flush()
    end) =~ "no match of right hand side value: [\"12\"]"
  end

  describe "LiveViewNative.Stylesheet sigil" do
    test "single rules supported" do
      output = MockSheet.compile_ast(["color-yellow"])

      assert output == %{"color-yellow" => ["rule-yellow"]}
    end

    test "multiple rules and class name pattern matching" do
      output = MockSheet.compile_ast(["color-number-4"])

      assert output == %{"color-number-4" => ["rule-1", "rule-24"]}
    end

    test "can convert the output to a string" do
      output = MockSheet.compile_string(["color-number-3"])

      assert output == ~s(%{"color-number-3" => ["rule-1", "rule-23"]})
    end
  end
end
