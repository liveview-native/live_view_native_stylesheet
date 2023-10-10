defmodule LiveViewNative.Stylesheet.Compiler do
  # @callback compile(rules::binary) :: list
  # @callback sigil_SHEET(sheet::binary, modifier::atom) :: list()
  # @callback sigil_RULES(block::binary, modifier::atom) :: list()

  def sheet(blocks, compiler) do
    blocks =
      blocks
      |> eval_quoted()
      |> compiler.()

    quote bind_quoted: [blocks: Macro.escape(blocks)] do
      for {arguments, body} <- blocks do
        def class(unquote_splicing(arguments)) do
          sigil_RULES(unquote(body), nil)
        end
      end
    end
  end

  def rules(body, compiler) do
    body
    |> eval_quoted()
    |> compiler.()
    |> Enum.map(&escape(&1))
  end

  defp eval_quoted(expr) when is_binary(expr), do: expr
  defp eval_quoted({:<<>>, _, [expr]}), do: expr

  defp escape({operator, meta, arguments}) when operator in [:<>] do
    {operator, meta, Enum.map(arguments, &escape(&1))}
  end
  defp escape({Elixir, _meta, expr}), do: expr
  defp escape({identity, annotations, arguments}) do
    {:{}, [], [identity, annotations, Enum.map(arguments, &escape(&1))]}
  end
  defp escape(literal), do: literal

  def compile_rules(format, rules) do
    compiler = fetch(format)
    compiler.compile_rules(rules)
  end

  def compile_sheet(format, class_names) do
    compiler = fetch(format)
    compiler.compile_sheet(class_names)
  end

  def fetch(format) do
    with {:ok, formats} <- Application.fetch_env(:live_view_native_stylesheet, :formats),
    {:ok, compiler} <- Keyword.fetch(formats, format) do
      compiler
    else
      :error -> "No compiler found for `#{inspect(format)}`"
    end
  end
end
