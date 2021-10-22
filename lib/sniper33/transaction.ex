defmodule Sniper33.Transaction do
  @moduledoc false

  alias Sniper33.Utils

  defstruct [
    :from,
    :to,
    :value,
    :link,
    :address,
    :dex,
    :tweet_id,
    :tweet_created_at
  ]

  def parse_tweets(tweets) when is_list(tweets) do
    txs = tweets |> Enum.map(&from_tweet(&1)) |> Enum.reject(&is_nil(&1))

    Enum.reduce(txs, %{}, fn tx, state ->
      state
      |> record_sell(tx)
      |> record_buy(tx)
    end)
  end

  def from_tweet(%{
        tweet_id: tweet_id,
        created_at: created_at,
        content: raw_content
      }) do
    [transaction, address_info, link] =
      raw_content |> String.split("\n") |> Enum.reject(&(&1 == ""))

    [_, _, "#" <> address] = address_info |> String.split(" ")

    [_, _, value, _, "$" <> from, _, "$" <> to, _, "#" <> dex, _] =
      transaction |> String.split(" ")

    %__MODULE__{
      from: from,
      to: to,
      value: Utils.extract_value(value),
      link: link,
      address: address,
      dex: dex,
      tweet_id: tweet_id,
      tweet_created_at: created_at
    }
  rescue
    _ ->
      nil
  end

  defp record_sell(state, tx) do
    case state[tx.from] do
      nil ->
        value = Decimal.sub(0, tx.value)
        seller_count = 1

        Map.put(state, tx.from, %{
          value: value,
          seller_count: seller_count,
          sell_value: tx.value,
          links: [tx.link]
        })

      %{
        value: old_value
      } = info ->
        seller_count = info[:seller_count] || 0
        sell_value = Decimal.add(info[:sell_value] || Decimal.new(0), tx.value)
        value = Decimal.sub(old_value, tx.value)
        old_links = info[:links] || []
        new_links = [tx.link | old_links]

        new_info =
          info
          |> Map.put(:value, value)
          |> Map.put(:seller_count, seller_count + 1)
          |> Map.put(:sell_value, sell_value)
          |> Map.put(:links, new_links)

        Map.put(state, tx.from, new_info)
    end
  end

  defp record_buy(state, tx) do
    case state[tx.to] do
      nil ->
        value = Decimal.add(0, tx.value)
        buyer_count = 1

        Map.put(state, tx.to, %{
          value: value,
          buyer_count: buyer_count,
          buy_value: value,
          links: [tx.link]
        })

      %{
        value: old_value
      } = info ->
        buyer_count = info[:buyer_count] || 0
        buy_value = Decimal.add(info[:buy_value] || Decimal.new(0), tx.value)
        value = Decimal.add(old_value, tx.value)
        old_links = info[:links] || []
        new_links = [tx.link | old_links]

        new_info =
          info
          |> Map.put(:value, value)
          |> Map.put(:buyer_count, buyer_count + 1)
          |> Map.put(:buy_value, buy_value)
          |> Map.put(:links, new_links)

        Map.put(state, tx.to, new_info)
    end
  end
end
