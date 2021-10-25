# Sniper33

To start your sniper33:

  * export environment variable DATABASE_URL, for example: `ecto://USER:PASS@HOST/DATABASE`
  * export environment variable SNIPER33_TWITTER_TOKEN, you can get it from twitter developer account app
  * export environment variable SNIPER33_TWITTER_SYNC_INTERVAL, recommand set it to "180000", which means sync tweets per 3 mins
  * export environment variable SNIPER33_DISCORD_WEBHOOK, which is your discord webhook url

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Install Node.js dependencies with `npm install` inside the `assets` directory
  * Start Phoenix endpoint with `mix phx.server`

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
