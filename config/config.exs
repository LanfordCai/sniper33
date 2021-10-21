# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :sniper33,
  ecto_repos: [Sniper33.Repo]

# Configures the endpoint
config :sniper33, Sniper33Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "0V5PBl8FS64GiWazi497IuoEk8u2PvKTvK+zT/D3lY14Np2e6isOTUo5oQa9hprS",
  render_errors: [view: Sniper33Web.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Sniper33.PubSub,
  live_view: [signing_salt: "DHEO82v3"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
