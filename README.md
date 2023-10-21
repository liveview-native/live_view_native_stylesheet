# LiveViewNativeStylesheet

Stylesheet primitives for LiveView Native

The library is usually the dependency of another high level lib

## TODO:

* Similar to tailwind we need a running server that will be fed all class names from templates
* determine how style maps will be served to the client (separate file, embed in markup?)
* cache compiled stylesheets to avoid unnecessary recompilation
* on each code reload in Phoenix stylesheet recompilation should be attempted
* production sheet output

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `live_view_native_stylesheet` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:live_view_native_stylesheet, "~> 0.1.0"}
  ]
end
```

Next add the platforms and compilers to your application config:

```elixir
config :live_view_native_stylesheet, :parsers, 
  swiftui: LiveViewNative.SwiftUI.RulesParser

# For production environments, you can opt out of annotations
# for smaller outputs
config :live_view_native_stylesheet,
  annotations: false
```

## Building a stylesheet rules parser

```elixir
defmodule MyCustomerRulesParser do
  use LiveViewNative.Stylesheet.RulesParser, :swiftui

  defmacro __using__(_) do
    quote do
      import MyCustomRulesParser, only: [sigil_RULES: 2]
      import MyCustomRulesHelpers
    end
  end

  def parse(rules) do
    # your custom parser defined here
  end
end
```

The `format` passed in during the `use` will define a new `sigil_RULES/2` function within
your customer parser. The `format` is carried through this function so make sure it matches
the `format` used for the sheet itself.

You *must* implement the `__using__/1` macro and at least `import` `sigil_RULES/2` from your
custom parser. `sigil_RULES/2` is injected into your module from `LiveViewNative.Stylesheet.RulesParser`.
This is also a good place to include other `import`s that are necessary to support the compilation of
the final stylsheet. In the example above `import MyCustomRulesHelpers` may include additional helpers
available to your parser's rule set.

You *must* implement the `parse/1` function as this is your primary hook for parsing the rules
found within the body of each class from the sheet

## Writing stylesheets

New stylesheets can be defined specific to each platform. The 

```elixir
defmodule MySheet do
  use LiveViewNative.Stylesheet, :swiftui

  ~SHEET"""
  "color-" <> color_name do
    color(to_ime(color_name))
  end
  """

  def class("color-"<>color_name, _target) do
    ~RULES"""
    color(to_ime(color_name))
    """
  end

  def class("star-red", _target) do
    ~RULES"""
    background(alignment: .leading){:star-red}
    """
  end

  def class("star-blue", _target) do
    ~RULES"""
    background(alignment: .trailing){:star-blue}
    """
  end
end
```

## Compiling stylesheets

Stylesheets output only exactly what class names are matched in the templates. This is true of pattern matched class names as well. This
keeps the output small lookups fast on the client.

To compile a stylesheet you simply provide a list of class names and a map of ASTs will be produced. Using `MySheet` from above:

```elixir
MySheet.compile(~w[color-blue star-red])

=> %{
  "color-blue" => [{:color, [], [{:., [], [nil, :blue]}]}]    [["color", [[".blue", :IME]], nil]]
  "star-red" => [{:background, [], [[alignment: {:., [], [nil, :trailing]}, content: :"star-red"]]}]
}
```

This map will be sent to the client for looking up the styles at runtime and applying with little to no parsing on the client side:

```heex
<Text class="color-blue star-red">
  ABCDEF
  <Star template="star-red" class="color-red"/>
</Text>
```

Some style/modifier values make more sense as attrs on the element itself. Custom parsers should
support `attr(value)`:

```elixir
def class("searchable", _target) do
  ~RULES"""
  searchable(placeholder: attr(placeholder))
  """
end
```

This will instruct the client to get the value from the element the class name matches on:

```heex
<Text class="searchable" placeholder={@placeholder}>Hello, world!</Text>
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/live_view_native_stylesheet>.

