use Mix.Config

config :logger, :console,
  level: :debug,
  format: "$metadata$message\n",
  metadata: [:user_id]
