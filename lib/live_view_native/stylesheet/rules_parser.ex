defmodule LiveViewNative.Stylesheet.RulesParser do
  defmacro sigil_RULES({:<<>>, _meta, [rules]}, _modifier) do
    opts = [
      file: __CALLER__.file,
      line: __CALLER__.line + 1,
      module: __CALLER__.module,
      variable_context: nil
    ]

    compiled_rules =
      rules
      |> String.replace("{", "<%=")
      |> String.replace("}", "%>")
      |> EEx.compile_string()

    quote do
      LiveViewNative.Stylesheet.RulesParser.parse(unquote(compiled_rules), @format, unquote(opts))
    end
  end

  def fetch(format) do
    with {:ok, plugin} <- LiveViewNative.fetch_plugin(format),
      parser when not is_nil(parser) <- plugin.stylesheet_rules_parser do
        {:ok, parser}
    else
      :error ->
        {:error, "No parser found for `#{inspect(format)}`"}
    end
  end

  def parse(body, format, opts \\ []) do
    case fetch(format) do
      {:ok, parser} ->
        opts =
          opts
          |> Keyword.put_new(:variable_context, Elixir)
          |> Keyword.update(:file, "", &Path.basename/1)
          
        body
        |> String.replace("\r\n", "\n")
        |> parser.parse(opts)
      {:error, message} -> raise message
    end
  end
end
