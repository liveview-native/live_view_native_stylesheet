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
config :live_view_native_stylesheet, :formats, 
  swiftui: LiveViewNative.SwiftUI.StylesheetCompiler
```

## Building a stylesheet compiler

```elixir
defmodule MyCustomerStyleCompiler do
  @behavior LiveViewNative.Stylesheet.Compiler

  def compile_sheet(sheet) do
    # parse class names into {<funcSignature>, <rulesBody>}
  end

  def compile_rules(rules) do
    # parse rules and produce AST
  end

  defmacro sigil_SHEET(sheet, _modifier) do
    LiveViewNative.Stylesheet.Compiler.sheet(sheet, &__MODULE__.compile_sheet/1)
  end

  defmacro sigil_RULES(rules, _modifier) do
    LiveViewNative.Stylesheet.Compiler.rules(rules, &__MODULE__.compile_rules/1)
  end
end
```

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
    "color(.#{color_name})"
  end

  def class("star-red", _target) do
    "background(alignment: .leading){:star-red}"
  end

  def class("star-blue", _target) do
    "background(alignment: .trailing){:star-blue}"
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
  "color-blue" => [["color", [[".blue", :IME]], nil]]
  "star-red" => [["background", [["alignment", [".trailing", :IME]], :star-red]]
}
```

This map will be sent to the client for looking up the styles at runtime and applying with little to no parsing on the client side:

```heex
<Text class="color-blue star-red">
  ABCDEF
  <:star-red>
    <Star class="color-red"/>
  </:star-red>
</Text>
```

Some style/modifier values make more sense as attrs on the element itself. Compilers should
support `attr(value)`:

```elixir
def class("searchable", _target) do
  "searchable(placeholder: attr(placeholder))"
end
```

This will instruct the client to get the value from the element the class name matches on:

```heex
<Text class="searchable" placeholder={@placeholder}>Hello, world!</Text>
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/live_view_native_stylesheet>.

