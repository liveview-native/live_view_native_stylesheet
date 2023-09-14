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

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/live_view_native_stylesheet>.

