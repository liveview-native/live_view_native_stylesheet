defmodule NullLayout do
  use LiveViewNative.Component,
    format: :mock

  import LiveViewNative.Stylesheet.Component

  embed_stylesheet NullSheet
end
