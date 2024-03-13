defmodule MockLayout do
  use LiveViewNative.Component,
    format: :mock

  embed_templates "layouts_swiftui/*"
end
