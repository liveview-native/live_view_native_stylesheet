defmodule MockLayout do
  use LiveViewNative.Component,
    format: :mock

  import LiveViewNative.Stylesheet.Component

  embed_templates "layouts_swiftui/*"
  embed_stylesheet MockSheet
end