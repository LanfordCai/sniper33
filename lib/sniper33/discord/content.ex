defmodule Sniper33.Discord.Content do
  @moduledoc false

  @avatar_url "https://pbs.twimg.com/profile_images/1398660821216006145/QuCSo8wy_400x400.jpg"

  @green "6080391"
  @red "14964065"

  def content(:sniper_stats, stats, latest_tweet_created_at) do
    embeds =
      Enum.map(stats, fn {symbol, stats, type} ->
        color = if type == :gainer, do: @green, else: @red

        %{
          "color" => color,
          "title" => "#{symbol}",
          "fields" => [
            %{
              "name" => "NetInflow(USD)",
              "value" => "#{Decimal.to_string(stats.value)}",
              "inline" => true
            },
            %{
              "name" => "BuyerCount",
              "value" => "#{stats[:buyer_count] || 0}",
              "inline" => true
            },
            %{
              "name" => "SellerCount",
              "value" => "#{stats[:seller_count] || 0}",
              "inline" => true
            },
            %{
              "name" => "Inflow(USD)",
              "value" => "#{Decimal.to_string(stats[:buy_value] || Decimal.new(0))}",
              "inline" => true
            },
            %{
              "name" => "Outflow(USD)",
              "value" => "#{Decimal.to_string(stats[:sell_value] || Decimal.new(0))}",
              "inline" => true
            }
          ]
        }
      end)

    %{
      "username" => "DefiSniper Stats 🔥",
      "avatar_url" => "#{@avatar_url}",
      "content" =>
        "Lastest Tweet Created At: #{NaiveDateTime.to_string(latest_tweet_created_at)}(UTC)",
      "embeds" => embeds
    }
  end
end
