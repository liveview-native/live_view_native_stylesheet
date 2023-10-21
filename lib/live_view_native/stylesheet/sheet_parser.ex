defmodule LiveViewNative.Stylesheet.SheetParser do
  alias LiveViewNative.Stylesheet.SheetParser.Block
  alias LiveViewNative.Stylesheet.SheetParser.Parser

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
        module: __CALLER__.module,
        line: __CALLER__.line + 1
      )

    quote bind_quoted: [blocks: Macro.escape(blocks)] do
      for {arguments, body} <- blocks do
        def class(unquote_splicing(arguments)) do
          sigil_RULES(unquote(body), nil)
        end
      end
    end
  end
end
