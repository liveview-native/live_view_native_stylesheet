defmodule LiveViewNative.Stylesheet.RulesParser.Helpers do
  @moduledoc false
  import NimbleParsec
  import LiveViewNative.Stylesheet.SheetParser.Tokens, only: [variable: 0, enclosed: 4]

  @helper_functions [
    "to_atom",
    "to_integer",
    "to_float",
    "to_boolean",
    "camelize",
    "underscore"
  ]

  def parse(opts \\ []) do
    additional_functions = Keyword.get(opts, :additional, [])

    choice(Enum.map(@helper_functions ++ additional_functions, &string(&1)))
    |> enclosed("(", variable(), ")")
    |> post_traverse({:to_function_call_ast, []})
    |> post_traverse({:tag_as_elixir_code, []})
  end

  defmacro __using__(opts \\ []) do
    module_name = __MODULE__

    quote do
      import NimbleParsec

      import LiveViewNative.Stylesheet.SheetParser.PostProcessors,
        only: [to_function_call_ast: 5, to_elixir_variable_ast: 5, tag_as_elixir_code: 5]

      import LiveViewNative.Stylesheet.RulesHelpers

      defparsec(:helper_function, unquote(module_name).parse(unquote(opts)),
        export_combinator: true
      )
    end
  end
end
