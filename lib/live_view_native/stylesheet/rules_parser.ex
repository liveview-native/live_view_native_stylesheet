defmodule LiveViewNative.Stylesheet.RulesParser do
  @callback parse(rules :: binary, opts :: keyword()) :: list
  @macrocallback __using__(format :: atom) :: tuple

  defmacro __using__(format) do
    quote do
      @behaviour LiveViewNative.Stylesheet.RulesParser

      defmacro sigil_RULES(rules, _modifier) do
        opts = [
          file: __CALLER__.file,
          line: __CALLER__.line + 1,
          module: __CALLER__.module,
          context: nil
        ]

        LiveViewNative.Stylesheet.RulesParser.parse(rules, unquote(format), opts)
      end
    end
  end

  def fetch(format) do
    with {:ok, parsers} <- Application.fetch_env(:live_view_native_stylesheet, :parsers),
         {:ok, parser} <- Keyword.fetch(parsers, format) do
      {:ok, parser}
    else
      :error ->
        {:error, "No parser found for `#{inspect(format)}`"}
    end
  end

  def parse(body, format, opts \\ []) do
    case fetch(format) do
      {:ok, parser} ->
        body
        |> LiveViewNative.Stylesheet.Utils.eval_quoted()
        |> String.replace("\r\n", "\n")
        |> parser.parse(Keyword.put_new(opts, :context, Elixir))
        |> List.wrap()
        |> Enum.map(&escape(&1))
      {:error, message} -> raise message
    end
  end

  defp escape({operator, meta, arguments}) when operator in [:<>] do
    {operator, meta, Enum.map(arguments, &escape(&1))}
  end
  defp escape({Elixir, _meta, expr}), do: expr
  defp escape({identity, annotations, arguments}) do
    {:{}, [], [identity, annotations, escape(arguments)]}
  end
  defp escape([{key, value} | tail]) do
    [{key, escape(value)} | escape(tail)]
  end
  defp escape([argument | tail]) do
    [escape(argument) | escape(tail)]
  end
  defp escape(literal), do: literal
end
