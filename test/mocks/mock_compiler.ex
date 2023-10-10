defmodule MockCompiler do
  # @behaviour LiveViewNative.Stylesheet.Compiler

  def compile_sheet(_sheet) do
    [
      {["color-yellow", {:_target, [], Elixir}], "rule-21"},
      {
        [{:<>, [context: LiveViewNative.Stylesheet.Compiler, imports: [{2, Kernel}]], ["color-hex-", {:number, [], Elixir}]}, {:_target, [], LiveViewNative.Stylesheet.Compiler}],
         "rule-31\nrule-22"
      }
    ]
  end

  def compile_rules(rules) do
    rules
    |> String.split("\n", trim: true)
    |> Enum.map(&compile_rule(&1))
  end

  defp compile_rule("rule-31") do
    {:<>, [], ["rule-31-", {Elixir, [], {:number, [], Elixir}}]}
  end

  defp compile_rule("rule-21") do
    {:foobar, [], [1, 2, 3]}
  end

  defp compile_rule("rule-22") do
    {:foobar, [], [1, 2, {Elixir, [], {:number, [], Elixir}}]}
  end

  defp compile_rule("rule-" <> number) do
    {int, _} = Integer.parse(number)
    int
  end

  defp compile_rule(rule), do: rule

  defmacro sigil_SHEET(sheet, _modifier) do
    LiveViewNative.Stylesheet.Compiler.sheet(sheet, &__MODULE__.compile_sheet/1)
  end

  defmacro sigil_RULES(rules, _modifier) do
    LiveViewNative.Stylesheet.Compiler.rules(rules, &__MODULE__.compile_rules/1)
  end
end
