defmodule Sniper33.Discord.Poster do
  @moduledoc false

  use GenServer
  require Logger

  alias Sniper33.Discord.{Content, Requester}
  alias Sniper33.Twitter.Tweet
  alias Sniper33.Transaction

  def start_link(user_id) do
    GenServer.start_link(
      __MODULE__,
      %{user_id: user_id},
      name: __MODULE__
    )
  end

  @impl true
  def init(state) do
    webhooks =
      Application.get_env(:sniper33, :discord_webhooks)
      |> Enum.reject(&is_nil(&1))

    if Enum.empty?(webhooks) do
      Logger.error("[#{__MODULE__}] empty webhooks!")
      raise "Empty Webhooks!"
    end

    push_1h_stats()
    Logger.info("[#{__MODULE__}] started!")
    content = Content.content(:poster_started)
    Enum.each(webhooks, &Requester.post(&1, content))

    {:ok, Map.put(state, :webhooks, webhooks)}
  end

  @impl true
  def handle_info(:push_1h_stats, %{user_id: user_id, webhooks: webhooks} = state) do
    Logger.info("[#{__MODULE__}] ready to push stats")

    tweets = user_id |> Tweet.in_hours(1)

    if !Enum.empty?(tweets) do
      stats =
        tweets
        |> Transaction.parse_tweets()
        |> order_by_net_value()
        |> filter_out_stats()

      if !Enum.empty?(stats) do
        latest_tweet_created_at = hd(tweets).created_at
        content = Content.content(:sniper_stats, stats, latest_tweet_created_at)
        Enum.each(webhooks, &Requester.post(&1, content))
      end
    else
      :ignore
    end

    push_1h_stats()
    {:noreply, state}
  end

  defp push_1h_stats() do
    Process.send_after(self(), :push_1h_stats, 60 * 60000)
  end

  defp order_by_net_value(stats) do
    Enum.sort_by(
      stats,
      fn {_symbol, stats} ->
        stats[:value] || Decimal.new(0)
      end,
      fn v1, v2 ->
        Decimal.compare(v1, v2) == :gt
      end
    )
  end

  @common_coins ["USDC", "USDT", "DAI", "UST", "stETH", "ETH", "BTC", "WBTC", "WETH"]
  defp filter_out_stats(raw_stats) when is_list(raw_stats) do
    stats =
      Enum.reject(raw_stats, fn {symbol, _stats} ->
        symbol in @common_coins
      end)

    gainers =
      stats
      |> Enum.take(5)
      |> Enum.filter(fn {_symbol, stats} ->
        buyer_count = stats[:buyer_count] || 0
        Decimal.compare(stats.value, 1_000_000) != :lt or buyer_count >= 3
      end)
      |> Enum.map(fn {symbol, stats} ->
        {symbol, stats, :gainer}
      end)

    losers =
      stats
      |> Enum.reverse()
      |> Enum.take(5)
      |> Enum.filter(fn {_symbol, stats} ->
        seller_count = stats[:seller_count] || 0
        Decimal.compare(stats.value, -1_000_000) != :gt or seller_count >= 3
      end)
      |> Enum.map(fn {symbol, stats} ->
        {symbol, stats, :loser}
      end)

    gainers ++ losers
  end
end
