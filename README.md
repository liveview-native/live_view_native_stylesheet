# LiveViewNativeStylesheet

Stylesheet primitives for LiveView Native

The library is usually the dependency of another high level lib

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
config :live_view_native_stylesheet, :platforms, 
  swiftui: LiveViewNative.SwiftUI.StylesheetCompiler
```

## Building a stylesheet compiler

```elixir
defmodule MyCustomerStyleCompiler do
  @behavior LiveViewNative.Stylesheet.Compiler

  def compile(rules) do
    # parse rules and produce AST
  end
end
```

## Writing stylesheets

New stylesheets can be defined specific to each platform. The 

```elixir
defmodule MySheet do
  use LiveViewNative.Stylesheet, :swiftui

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

To compile a stylesheet you simply provide a list of class names and a map of ASTs will be produced. Using `MySheet` from above:

```elixir
MySheet.compile(~w[color-blue star-red])

=> %{
  "color-blue" => [["color", [[".blue", :IMF]], nil]]
  "star-red" => [["background", [["alignment", [".trailing", :IMF]], :star-red]]
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

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/live_view_native_stylesheet>.

