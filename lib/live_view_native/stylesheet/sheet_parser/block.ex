defmodule LiveViewNative.Stylesheet.SheetParser.Block do
  @moduledoc false
  import NimbleParsec
  import LiveViewNative.Stylesheet.SheetParser.Tokens
  import LiveViewNative.Stylesheet.SheetParser.PostProcessors

  string_with_variable =
    double_quoted_string()
    |> ignore_whitespace()
    |> ignore(string("<>"))
    |> ignore_whitespace()
    |> concat(variable())
    |> post_traverse({:block_open_with_variable_to_ast, []})

  key_value_pairs =
    ignore_whitespace()
    |> non_empty_comma_separated_list(key_value_pair())
    |> wrap()

  block_open =
    choice([
      string_with_variable,
      double_quoted_string()
    ])
    |> optional(
      ignore_whitespace()
      |> ignore(string(","))
      |> ignore_whitespace()
      |> concat(key_value_pairs)
    )
    |> ignore(
      repeat(
        lookahead_not(string(" do"))
        |> concat(whitespace_char())
      )
    )
    |> ignore(string(" do"))
    |> post_traverse({:block_open_to_ast, []})

  block_close =
    ignore_whitespace()
    |> ignore(string("end"))

  block_contents_as_string =
    repeat(
      lookahead_not(block_close)
      |> choice([
        string("\n")
        |> ignore_whitespace(),
        ascii_string([], not: [], max: 1)
      ])
    )
    |> concat(whitespace(min: 1))
    |> reduce({Enum, :join, [""]})
    |> map({String, :trim_leading, []})

  defparsec(
    :class_names,
    repeat(
      ignore_whitespace()
      |> concat(block_open)
      |> concat(block_contents_as_string)
      |> concat(block_close)
      |> post_traverse({:wrap_in_tuple, []})
    )
    |> ignore_whitespace()
    |> eos(),
    export_combinator: true
  )
end
