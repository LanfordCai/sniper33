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
    webhook = Application.get_env(:sniper33, :discord_webhook)

    if is_nil(webhook) do
      Logger.error("[#{__MODULE__}] empty webhook!")
      raise "Empty Webhook!"
    end

    push_1h_stats()
    Logger.info("[#{__MODULE__}] started!")
    {:ok, Map.put(state, :webhook, webhook)}
  end

  @impl true
  def handle_info(:push_1h_stats, %{user_id: user_id, webhook: webhook} = state) do
    Logger.info("[#{__MODULE__}] ready to push stats")

    tweets = user_id |> Tweet.in_hours(1)

    if !Enum.empty?(tweets) do
      stats =
        tweets
        |> Transaction.parse_tweets()
        |> order_by_net_value()
        |> filter_out_stats()

      latest_tweet_created_at = hd(tweets).created_at
      content = Content.content(:sniper_stats, stats, latest_tweet_created_at)
      Requester.post(webhook, content)
    else
      :ignore
    end

    push_1h_stats()
    {:noreply, state}
  end

  defp push_1h_stats() do
    Process.send_after(self(), :push_1h_stats, 10000)
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

  @stable_coins ["USDC", "USDT", "DAI", "UST"]
  defp filter_out_stats(raw_stats) when is_list(raw_stats) do
    stats =
      Enum.reject(raw_stats, fn {symbol, _stats} ->
        symbol in @stable_coins
      end)

    gainers =
      stats
      |> Enum.take(5)
      |> Enum.filter(&Decimal.positive?(elem(&1, 1).value))
      |> Enum.map(fn {symbol, stats} ->
        {symbol, stats, :gainer}
      end)

    losers =
      stats
      |> Enum.reverse()
      |> Enum.take(5)
      |> Enum.filter(&(!Decimal.positive?(elem(&1, 1).value)))
      |> Enum.map(fn {symbol, stats} ->
        {symbol, stats, :loser}
      end)

    gainers ++ losers
  end
end
