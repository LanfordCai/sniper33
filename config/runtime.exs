import Config

config :sniper33,
  twitter_token: System.get_env("SNIPER33_TWITTER_TOKEN"),
  sync_interval: System.get_env("SNIPER33_TWITTER_SYNC_INTERVAL"),
  discord_webhooks: [
    System.get_env("SNIPER33_DISCORD_WEBHOOK"),
    System.get_env("SNIPER33_SUB_DISCORD_WEBHOOK")
  ],
  twitter_user_id: "1374833659686031363"
