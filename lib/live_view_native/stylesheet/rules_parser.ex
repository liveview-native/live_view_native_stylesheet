defmodule LiveViewNative.Stylesheet.RulesParser do
  @moduledoc false

  defmacro sigil_RULES({:<<>>, _meta, [rules]}, opts) do
    opts = [
      file: __CALLER__.file,
      line:
        if is_list(opts) && is_integer(Keyword.get(opts, :line)) do
          Keyword.get(opts, :line)
        else
          __CALLER__.line + 1
        end,
      module: __CALLER__.module,
      variable_context: nil
    ]

    compiled_rules =
      rules
      |> String.replace("{", "<%=")
      |> String.replace("}", "%>")
      |> precompile_string()

    quote do
      LiveViewNative.Stylesheet.RulesParser.parse(unquote(compiled_rules), @format, unquote(opts))
    end
  end

  def precompile_string(rules) do
    {:ok, tokens} = EEx.tokenize(rules, [])

    tokens = Enum.map(tokens, &rewrite_expr(&1))

    EEx.Compiler.compile(tokens, rules, [])
  end

  defp rewrite_expr({:expr, mark, chars, meta}) do
    {:expr, mark, ~c"LiveViewNative.Stylesheet.RulesParser.handle_interpolation(" ++ chars ++ ~c")", meta}
  end

  defp rewrite_expr(expr), do: expr

  def handle_interpolation(nil), do: "nil"
  def handle_interpolation(other), do: other

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
          |> Keyword.update(:file, "nofile", &Path.basename/1)

        body
        |> String.replace("\r\n", "\n")
        |> parser.parse(opts)
      {:error, message} -> raise message
    end
  end
end
