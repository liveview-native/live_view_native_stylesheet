defmodule LiveViewNativeStylesheetTest do
  use ExUnit.Case
  doctest LiveViewNative.Stylesheet

  defmodule MockCompiler do
    @behaviour LiveViewNative.Stylesheet.Compiler

    def compile(rules) do
      compiled_rules = %{
        "rule-1" => 1,
        "rule-2" => 2,
        "rule-3" => 3,
        "rule-4" => 4,
        "rule-5" => 5
      }

      String.split(rules, "\n", trim: true)
      |> Enum.map(fn(rule) ->
        Map.get(compiled_rules, rule)
      end)
    end
  end

  defmodule MockSheet do
    use LiveViewNative.Stylesheet, :mock

    def class("color-red", _target) do
      """
      rule-1
      rule-3
      """
    end

    def class("color-blue", target: :watch) do
      """
      rule-4
      rule-5
      """
    end

    def class("color-blue", _target) do
      "rule-2"
    end
  end

  setup do
    Application.put_env(:live_view_native_stylesheet, :platforms, mock: MockCompiler)

    on_exit(fn ->
      Application.delete_env(:live_view_native_stylehseet, :platforms)
    end)
  end

  test "will use registered platform compiler to compile ruleset" do
    output = LiveViewNative.Stylesheet.compile(:mock, "rule-2")
    assert output == [2]
  end

  test "will compile the rules for all listed classes" do
    output = MockSheet.compile(["color-blue", "color-red"], target: nil)

    assert output == %{"color-blue" => [2], "color-red" => [1,3]}
  end

  test "will compile the rules for a specific target" do
    output = MockSheet.compile(["color-blue", "color-red"], target: :watch)

    assert output == %{"color-blue" => [4,5], "color-red" => [1,3]}
  end
end
