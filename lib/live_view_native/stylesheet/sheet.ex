defmodule LiveViewNative.Stylesheet.Sheet do
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
