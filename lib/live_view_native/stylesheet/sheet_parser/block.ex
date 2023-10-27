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
    |> pre_traverse({__MODULE__, :get_position, []})
    |> post_traverse({__MODULE__, :combine_with_position, []})

  def get_position(rest, args, context, {line, _}, _) do
    context =
      context
      |> Map.put(:block_file, context.context.file)
      |> Map.put(:block_line, line + context.context.source_line)
      |> Map.put(:block_module, context.context.module)

    {rest, args, context}
  end

  def combine_with_position(rest, [body], context, _, _) do
    opts =
      if context.context.annotations do
        [
          file: context.block_file,
          line: context.block_line,
          module: context.block_module,
          annotations: context.context.annotations
        ]
      else
        [
          annotations: context.context.annotations
        ]
      end

    context =
      Map.drop(context, [:block_line, :block_file, :block_module])

    {rest, [body, opts], context}
  end

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
