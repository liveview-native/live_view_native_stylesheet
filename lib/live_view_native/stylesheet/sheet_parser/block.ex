defmodule LiveViewNative.Stylesheet.SheetParser.Block do
  @moduledoc false
  import NimbleParsec
  import LiveViewNative.Stylesheet.SheetParser.Tokens
  import LiveViewNative.Stylesheet.SheetParser.Expressions
  alias LiveViewNative.Stylesheet.SheetParser.PostProcessors
  alias LiveViewNative.Stylesheet.SheetParser.Parser

  string_with_variable =
    double_quoted_string()
    |> ignore_whitespace()
    |> ignore(string("<>"))
    |> ignore_whitespace()
    |> concat(variable())
    |> post_traverse({PostProcessors, :block_open_with_variable_to_ast, []})

  block_open =
    choice([
      string_with_variable,
      double_quoted_string()
    ])
    |> optional(
      ignore_whitespace()
      |> ignore(string(","))
      |> ignore_whitespace()
      |> concat(key_value_pairs())
    )
    |> ignore_whitespace()
    |> ignore(string("do"))
    |> post_traverse({PostProcessors, :block_open_to_ast, []})

  block_close =
    ignore(string("end"))

  block_contents_as_string =
    repeat(
      lookahead_not(
        ignore_whitespace()
        |> choice([block_close, eos()])
      )
      |> choice([
        string("\n")
        |> ignore(whitespace_except(?\n, min: 1)),
        ascii_string([], not: [], max: 1)
      ])
    )
    |> concat(whitespace(min: 1))
    |> reduce({Enum, :join, [""]})
    |> map({String, :replace_prefix, ["\n", ""]})

  defcombinator(
    :class_block,
    ignore_whitespace()
    |> concat(block_open)
    |> concat(block_contents_as_string)
    |> concat(Parser.expected(block_close, error_message: "expected an end"))
    |> post_traverse({PostProcessors, :wrap_in_tuple, []}),
    export_combinator: true
  )

  defparsec(
    :class_names,
    repeat(
      Parser.start(),
      choice([
        comment(),
        parsec(:class_block)
      ])
    )
    |> ignore_whitespace()
    |> Parser.expected(eos(), error_message: "invalid class header")
  )
end
