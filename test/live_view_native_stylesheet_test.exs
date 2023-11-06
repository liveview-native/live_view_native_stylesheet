defmodule LiveViewNative.StylesheetTest do
  use ExUnit.Case
  doctest LiveViewNative.Stylesheet

  test "will compile the rules for all listed classes" do
    output = MockSheet.compile_ast(["color-blue", "color-red"], target: nil)

    assert output == %{"color-blue" => [2], "color-red" => [1,3,4]}
  end

  test "will compile the rules for a specific target" do
    output = MockSheet.compile_ast(["color-blue", "color-red"], target: :watch)

    assert output == %{"color-blue" => [4,5], "color-red" => [1,3,4]}
  end

  test "won't fail when an class name isn't found" do
    output = MockSheet.compile_ast(["foobar"], target: :watch)

    assert output == %{}
  end

  test "can compile without target, will default to `target: :all`" do
    output = MockSheet.compile_ast(["color-blue", "color-red"])

    assert output == %{"color-blue" => [2], "color-red" => [1,3,4]}
  end

  test "can compile for a single class name" do
    output = MockSheet.compile_ast("color-blue")

    assert output == %{"color-blue" => [2]}
  end

  test "can compile when a rule set is not a list" do
    output = MockSheet.compile_ast("single")

    assert output == %{"single" => [{:single, [], [1]}]}
  end

  test "can compile custom classes using the RULES sigil" do
    output = MockSheet.compile_ast("custom-123")

    assert output == %{"custom-123" => [{:foobar, [], [1, 2, 123]}]}

    output = MockSheet.compile_ast("custom-124")
    assert output == %{"custom-124" => [{:foobar, [], [1, 2, 124]}]}
  end

  test "can compile custom classes using the RULES sigil (2)" do
    output = MockSheet.compile_ast("custom-multi-123-456")

    assert output == %{"custom-multi-123-456" => [
      {:foobar, [], [1, 2, 123]},
      {:bazqux, [], [3, 4, 456]}
    ]}
  end

  describe "LiveViewNative.Stylesheet sigil" do
    test "single rules supported" do
      output = MockSheet.compile_ast(["color-yellow"], target: :all)

      assert output == %{"color-yellow" => [{:foobar, [], [1, 2, 3]}]}
    end

    test "multiple rules and class name pattern matching" do
      output = MockSheet.compile_ast(["color-hex-123"], target: :all)

      assert output == %{"color-hex-123" => ["rule-31-123", {:foobar, [], [1, 2, "123"]}]}
    end

    test "can take a `as: :string` option to convert the output to a string" do
      output = MockSheet.compile_string(["color-hex-123"])

      assert output == ~s(%{"color-hex-123" => ["rule-31-123", {:foobar, [], [1, 2, "123"]}]})
    end
  end
end
