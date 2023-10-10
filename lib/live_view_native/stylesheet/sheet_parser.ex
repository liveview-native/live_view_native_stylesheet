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
end
