defmodule LiveViewNative.Stylesheet.Rules do
  defmacro __using__(format) do
    quote do
      def sigil_RULES(rules, _modifier) do
        LiveViewNative.Stylesheet.Rules.parse(rules, unquote(format))
      end
    end
  end

  def fetch_parser(format) do
    with {:ok, parsers} <- Application.fetch_env(:live_view_native_stylesheet, :parsers),
    {:ok, parser} <- Keyword.fetch(parsers, format) do
      {:ok, parser}
    else
      :error ->
        {:error, "No parser found for `#{inspect(format)}`"}
    end
  end

  def parse(body, format) do
    case fetch_parser(format) do
      {:ok, parser} ->
        body
        |> LiveViewNative.Stylesheet.Utils.eval_quoted()
        |> parser.parse()
        |> Enum.map(&escape(&1))
      {:error, message} -> raise message
    end
  end

  defp escape({operator, meta, arguments}) when operator in [:<>] do
    {operator, meta, Enum.map(arguments, &escape(&1))}
  end
  defp escape({Elixir, _meta, expr}), do: expr
  defp escape({identity, annotations, arguments}) do
    {:{}, [], [identity, annotations, Enum.map(arguments, &escape(&1))]}
  end
  defp escape(literal), do: literal
end
