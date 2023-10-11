defmodule LiveViewNative.Stylesheet.SheetParser.Modifiers do
  import LiveViewNative.Stylesheet.SheetParser.Tokens
  import LiveViewNative.Stylesheet.SheetParser.PostProcessors
  import LiveViewNative.Stylesheet.SheetParser.HelperFunctions
  import NimbleParsec

  defparsec(
    :key_value_pairs,
    ignore_whitespace()
    |> non_empty_comma_separated_list(key_value_pair())
    |> ignore_whitespace()
    |> wrap(),
    export_combinator: true
  )

  defparsec(
    :key_value_list,
    enclosed("[", parsec(:key_value_pairs), "]"),
    export_combinator: true
  )

  # .baz
  # .baz(0.1)
  implicit_ime = fn is_initial ->
    ignore(string("."))
    |> concat(word())
    |> wrap(optional(parsec(:brackets)))
    |> post_traverse({:to_implicit_ime_ast, [is_initial]})
  end

  # Foo.bar
  # Foo.baz(0.1)
  scoped_ime =
    module_name()
    |> ignore(string("."))
    |> concat(word())
    |> wrap(optional(parsec(:brackets)))
    |> post_traverse({:to_scoped_ime_ast, []})

  defparsec(
    :ime,
    choice([
      # Scoped
      # Color.red
      scoped_ime,
      # Implicit
      # .red
      implicit_ime.(true)
    ])
    |> repeat(
      # <other_ime>.red
      implicit_ime.(false)
    )
    |> post_traverse({:chain_ast, []})
  )

  defparsec(
    :nested_attribute,
    choice([
      #
      string("attr")
      |> wrap(parsec(:brackets))
      |> post_traverse({:to_attr_ast, []}),
      #
      helper_function()
      |> enclosed("(", variable(), ")")
      |> post_traverse({:to_function_call_ast, []})
      |> post_traverse({:tag_as_elixir_code, []}),
      #
      word()
      |> parsec(:brackets)
      |> post_traverse({:to_function_call_ast, []})
    ])
  )

  @bracket_child [
    literal(),
    parsec(:key_value_pairs),
    parsec(:nested_attribute),
    parsec(:ime),
    variable()
  ]

  defparsec(
    :brackets,
    enclosed("(", comma_separated_list(choice(@bracket_child)), ")")
  )

  content =
    choice([
      enclosed("[", comma_separated_list(choice(@bracket_child)), "]"),
      #
      newline_separated_list(choice(@bracket_child)),
      #
      choice(@bracket_child)
    ])
    |> post_traverse({:tag_as_content, []})
    |> wrap()

  defparsec(
    :modifier,
    ignore_whitespace()
    |> concat(word())
    |> parsec(:brackets)
    |> optional(enclosed("{", content, "}"))
    |> post_traverse({:to_function_call_ast, []}),
    export_combinator: true
  )

  defparsec(
    :modifiers,
    repeat(parsec(:modifier)),
    export_combinator: true
  )
end
