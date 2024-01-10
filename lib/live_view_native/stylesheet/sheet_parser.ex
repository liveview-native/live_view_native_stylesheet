defmodule LiveViewNative.Stylesheet.SheetParser do
  alias LiveViewNative.Stylesheet.SheetParser.{Block, Parser}

  def parse(sheet, opts \\ []) do
    file = Keyword.get(opts, :file, "")
    module = Keyword.get(opts, :module, "")
    line = Keyword.get(opts, :line, 1)

    parse_opts = [
      byte_offset: 0,
      context: %{
        file: file,
        source_line: line,
        module: module,
        annotations: Application.get_env(:live_view_native_stylesheet, :annotations, true)
      }
    ]

    result =
      sheet
      |> String.replace("\r\n", "\n")
      |> Block.class_names(parse_opts)
      |> Parser.error_from_result()

    case result do
      {:ok, rules, "" = _unconsumed, _context, _current_line_and_offset, _} ->
        rules

      {:error, message, _unconsumed, _context, {line, _}, _} ->
        raise CompileError,
          description: message,
          file: file,
          line: line
    end
  end

  defmacro sigil_SHEET(sheet, _modifier) do
    blocks =
      sheet
      |> LiveViewNative.Stylesheet.Utils.eval_quoted()
      |> LiveViewNative.Stylesheet.SheetParser.parse(
        file: __CALLER__.file,
        line: __CALLER__.line + 1,
        module: __CALLER__.module
      )

    for {arguments, opts, body} <- blocks do
      quote bind_quoted: [arguments: Macro.escape(arguments), body: body, opts: opts] do
        ast = LiveViewNative.Stylesheet.RulesParser.parse(body, @format, opts)

        def class(unquote_splicing(arguments)) do
          unquote(ast)
        end
      end
    end
  end
end
