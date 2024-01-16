import Config

config :live_view_native, :plugins, [
  MockClient
]

config :live_view_native_stylesheet,
  content: [
    "test/**/*.*"
  ],
  output: "priv/static/assets"