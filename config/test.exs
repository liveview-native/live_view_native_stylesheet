import Config

config :live_view_native, :plugins, [
  MockClient
]

config :live_view_native_stylesheet,
  silence_embed_raise: true,
  content: [
    mock: [
      "test/**/*.*",
      {:live_view_native, "lib/**/*.*"}
    ]
  ]
