defmodule LiveViewNative.Stylesheet.SheetParser do
  def parse(sheet) do
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
    [
      {["color-rainbow", {:_target, [], Elixir}], "red\norange\nyellow\nblue\nindigo\nviolet"}
    ]
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
