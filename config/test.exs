import Config

config :logger, level: :error

config :live_view_native, :plugins, [
  MockClient
]

config :live_view_native_stylesheet,
  content: [
    mock: [
      "test/**/*.*",
      {:live_view_native, "lib/**/*.*"},
      {:another_library, "lib/**/*.*"}
    ]
  ],
  output: "priv/static/assets",
  attribute_parsers: [
    style: [
      other: &LiveViewNative.Stylesheet.Extractor.parse_style/2
    ]
  ]
