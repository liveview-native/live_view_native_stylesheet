defmodule LiveViewNative.StylesheetTest do
  use ExUnit.Case
  doctest LiveViewNative.Stylesheet

  describe "compiles rules based on target" do
    test "will compile the rules for all listed classes" do
      output = MockSheet.compile_ast(["color-blue", "color-red"], target: nil)

      assert output == %{
        "color-blue" => [{"blue", "3"}],
        "color-red" => [{"red", "1"}, {"red", "2"}, {"red", "3"}]
      }
    end

    test "can compile without target, will default to `target: :all`" do
      output = MockSheet.compile_ast(["color-blue", "color-red"])

      assert output == %{
        "color-blue" => [{"blue", "3"}],
        "color-red" => [{"red", "1"}, {"red", "2"}, {"red", "3"}]
      }
    end

    test "will compile the rules for a specific target" do
      output = MockSheet.compile_ast(["color-blue", "color-red"], target: :watch)

      assert output == %{
        "color-blue" => [{"sky", "1"}, {"sky", "2"}],
        "color-red" => [{"red", "1"}, {"red", "2"}, {"red", "3"}]
      }
    end
  end

  test "won't fail when an class name isn't found" do
    output = MockSheet.compile_ast(["unknown"], target: :watch)

    assert output == %{}
  end

  test "can compile for a single class name" do
    output = MockSheet.compile_ast("color-blue")

    assert output == %{
      "color-blue" => [{"blue", "3"}]
    }
  end

  test "can compile when a rule set is not a list" do
    output = MockSheet.compile_ast("single")

    assert output == %{"single" => [{:single, [], [1]}]}
  end

  describe "compiling custom classes using the RULES sigil" do
    test "captures variables" do
      output = MockSheet.compile_ast("custom-123")
      assert output == %{"custom-123" => [123]}

      output = MockSheet.compile_ast("custom-124")
      assert output == %{"custom-124" => [124]}
    end

    test "captures variables (2)" do
      output = MockSheet.compile_ast("custom-multi-123-456")

      assert output == %{"custom-multi-123-456" => [
        {:foobar, [], [1, 2, 123]},
        {:bazqux, [], [3, 4, 456]}
      ]}
    end

    test "supports interpolation" do
      output = MockSheet.compile_ast("custom-interpolate-ime-ignore")

      assert output == %{"custom-interpolate-ime-ignore" => [
        {:color, [], [color: [{:., [], [nil, :red]}]]}
      ]}
    end
  end


  describe "LiveViewNative.Stylesheet sigil" do
    test "single rules supported" do
      output = MockSheet.compile_ast(["color-yellow"], target: :all)

      assert output == %{"color-yellow" => [{:foobar, [], [1, 2, 3]}]}
    end

    test "can take a `as: :string` option to convert the output to a string" do
      output = MockSheet.compile_string(["color-blue"])

      assert output == ~s(%{"color-blue" => [{"blue", "3"}]})
    end
  end
end
