defmodule LiveViewNative.StylesheetTest do
  use ExUnit.Case
  doctest LiveViewNative.Stylesheet

  test "will compile the rules for all listed classes" do
    output = MockSheet.compile(["color-blue", "color-red"], target: nil)

    assert output == %{"color-blue" => [2], "color-red" => [1,3,4]}
  end

  test "will compile the rules for a specific target" do
    output = MockSheet.compile(["color-blue", "color-red"], target: :watch)

    assert output == %{"color-blue" => [4,5], "color-red" => [1,3,4]}
  end

  test "won't fail when an class name isn't found" do
    output = MockSheet.compile(["foobar"], target: :watch)

    assert output == %{}
  end

  test "can compile without target, will default to `target: :all`" do
    output = MockSheet.compile(["color-blue", "color-red"])

    assert output == %{"color-blue" => [2], "color-red" => [1,3,4]}
  end

  test "can compile for a single class name" do
    output = MockSheet.compile("color-blue")

    assert output == %{"color-blue" => [2]}
  end

  test "can compile when a rule set is not a list" do
    output = MockSheet.compile("single")

    assert output == %{"single" => [{:single, [], [1]}]}
  end

  describe "LiveViewNative.Stylesheet sigil" do
    test "single rules supported" do
      output = MockSheet.compile(["color-yellow"], target: :all)

      assert output == %{"color-yellow" => [{:foobar, [], [1, 2, 3]}]}
    end

    test "multiple rules and class name pattern matching" do
      output = MockSheet.compile(["color-hex-123"], target: :all)

      assert output == %{"color-hex-123" => ["rule-31-123", {:foobar, [], [1, 2, "123"]}]}
    end
  end
end
