import Config

config :live_view_native, :plugins, [
  MockClient
]

config :live_view_native_stylesheet,
  content: [
    mock: [
      "test/**/*.*",
      {:live_view_native, "lib/**/*.*"}
    ]
  ],
  output: "priv/static/assets"