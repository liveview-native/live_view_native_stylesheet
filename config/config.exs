import Config

config :logger, :level, :debug

import_config "#{config_env()}.exs"
