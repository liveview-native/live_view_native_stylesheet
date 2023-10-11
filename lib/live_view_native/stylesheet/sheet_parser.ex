defmodule LiveViewNative.Stylesheet.SheetParser do
  alias LiveViewNative.Stylesheet.SheetParser.Block

  def parse(sheet) do
    with {:ok, rules, "" = _unconsumed, _context, _current_line_and_offset, _} <-
           Block.class_names(sheet) do
      rules
    else
      {:error, message, _unconsumed, _context, {line, column}, _} ->
        # TODO: Improve errors to point
        # - Point to column with error in source SIGIL / sheet
        throw(
          SyntaxError.message(%{
            file: "Sheet",
            line: line,
            column: column,
            description: message
          })
        )
    end
  end

  defmacro sigil_SHEET(sheet, _modifier) do
    blocks =
      sheet
      |> LiveViewNative.Stylesheet.Utils.eval_quoted()
      |> LiveViewNative.Stylesheet.SheetParser.parse()

    quote bind_quoted: [blocks: Macro.escape(blocks)] do
      for {arguments, body} <- blocks do
        def class(unquote_splicing(arguments)) do
          sigil_RULES(unquote(body), nil)
        end
      end
    end
  end
end
