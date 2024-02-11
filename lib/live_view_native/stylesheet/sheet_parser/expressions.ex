defmodule LiveViewNative.Stylesheet.SheetParser.Expressions do
  @moduledoc false
  import NimbleParsec
  import LiveViewNative.Stylesheet.SheetParser.Parser
  import LiveViewNative.Stylesheet.SheetParser.Tokens
  alias LiveViewNative.Stylesheet.SheetParser.PostProcessors

  def enclosed(start, open, combinator, close, opts) do
    allow_empty? = Keyword.get(opts, :allow_empty?, true)

    close =
      expected(
        ignore(string(close)),
        error_message: "expected ‘#{close}’",
        error_parser: optional(non_whitespace())
      )

    start
    |> ignore(string(open))
    |> ignore_whitespace()
    |> concat(
      if allow_empty? do
        optional2(combinator)
      else
        combinator
      end
    )
    |> ignore_whitespace()
    |> concat(close)
  end

  #
  # Collections
  #

  def comma_separated_list(start \\ empty(), elem_combinator, opts \\ []) do
    delimiter_separated_list(
      start,
      elem_combinator,
      ",",
      Keyword.merge([allow_empty?: true], opts)
    )
  end

  defp delimiter_separated_list(combinator, elem_combinator, delimiter, opts) do
    allow_empty? = Keyword.get(opts, :allow_empty?, true)

    #  1+ elems
    non_empty =
      elem_combinator
      |> repeat(
        ignore_whitespace()
        |> ignore(string(delimiter))
        |> ignore_whitespace()
        |> concat(elem_combinator)
      )

    if allow_empty? do
      combinator
      |> optional2(non_empty)
    else
      combinator
      |> concat(non_empty)
    end

    # end
  end

  def key_value_pair() do
    ignore_whitespace()
    |> concat(word())
    |> concat(ignore(string(":")))
    |> ignore(whitespace(min: 1))
    |> concat(literal(error_parser: empty()))
    |> post_traverse({PostProcessors, :to_keyword_tuple_ast, []})
  end

  def key_value_pairs(opts \\ []) do
    comma_separated_list(
      empty(),
      key_value_pair(),
      opts
    )
    |> wrap()
  end
end
