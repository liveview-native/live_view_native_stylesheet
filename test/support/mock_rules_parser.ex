defmodule MockRulesParser do
  def parse(rules, opts) do
    rules
    |> String.split("\n", trim: true)
    |> Enum.map(&parse_rule(&1, opts))
  end

  defp parse_rule("rule-annotated", opts) do
    {:foobar,
     [
       file: Keyword.get(opts, :file),
       line: Keyword.get(opts, :line),
       module: Keyword.get(opts, :module)
     ], [1, 2, 3]}
  end

  defp parse_rule(rule, _), do: rule
end
