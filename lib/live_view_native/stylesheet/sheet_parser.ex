defmodule LiveViewNative.Stylesheet.SheetParser do
  alias LiveViewNative.Stylesheet.SheetParser.Block

  def parse(sheet) do
    {:ok, rules, _unconsumed, _context, _current_line_and_offset, _} = Block.rules_block(sheet)
    # parse sheet
    # example input
    #
    # "color-rainbow" do
    #   red
    #   orange
    #   yellow
    #   green
    #   blue
    #   indigo
    #   violet
    # end

    # expected parsed output
    # {["color-rainbow", {:_target, [], Elixir}], "red\norange\nyellow\nblue\nindigo\nviolet"}

    # the rules are parsed per compiler and separately
    # [
    #   {["color-rainbow", {:_target, [], Elixir}], "red\norange\nyellow\nblue\nindigo\nviolet"}
    # ]
    rules
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
