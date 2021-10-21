defmodule Sniper33.Twitter.Syncer do
  @moduledoc false

  use GenServer
  require Logger

  alias Sniper33.Twitter.{Client, Tweet}

  def start_link(user_id) when is_binary(user_id) do
    latest_tweet_id =
      case Tweet.latest(user_id) do
        nil -> "0"
        %{tweet_id: id} -> id
      end

    GenServer.start_link(
      __MODULE__,
      %{
        user_id: user_id,
        latest_tweet_id: latest_tweet_id,
        max_results: 100
      },
      name: name(user_id)
    )
  end

  defp name(user_id), do: :"#{user_id}_twitter_syncer"

  @impl true
  def init(state) do
    sync_tweets(interval())
    Logger.info("[#{__MODULE__}] started!")
    {:ok, state}
  end

  @impl true
  def handle_info(
        :sync_tweets,
        %{
          user_id: user_id,
          latest_tweet_id: latest_tweet_id,
          max_results: max_results
        } = state
      ) do
    Logger.info("[#{__MODULE__}] syncing new tweets with latest_tweet_id: #{latest_tweet_id}")

    opts = [
      since_id: latest_tweet_id,
      tweet_fields: [:created_at]
    ]

    new_state =
      case Client.get_timeline_by_user_id(user_id, max_results, opts) do
        {:ok, %{"data" => tweets}} ->
          Logger.info("[#{__MODULE__}] get #{Enum.count(tweets)} new tweets")
          insert_to_db(tweets, user_id)

          latest_tweet_id =
            case Tweet.latest(user_id) do
              nil -> "0"
              %{tweet_id: id} -> id
            end

          Map.put(state, :latest_tweet_id, latest_tweet_id)

        {:ok, %{"meta" => %{"result_count" => 0}}} ->
          state

        otherwise ->
          Logger.error("[#{__MODULE__}] get unexpected response: #{inspect(otherwise)}")
          state
      end

    sync_tweets(interval())
    {:noreply, new_state}
  end

  defp insert_to_db(tweets, user_id) do
    tweets
    |> Enum.each(fn tweet ->
      Tweet.new!(user_id, tweet)
    end)
  end

  defp sync_tweets(interval) do
    Process.send_after(self(), :sync_tweets, interval)
  end

  defp interval() do
    String.to_integer(Application.get_env(:sniper33, :sync_interval))
  end
end
