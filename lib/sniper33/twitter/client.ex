defmodule Sniper33.Twitter.Client do
  @moduledoc false

  alias Sniper33.Twitter.Requester

  @v2 "https://api.twitter.com/2"

  def get_user_by_id(user_id)
      when is_binary(user_id) do
    "#{@v2}/users/#{user_id}"
    |> Requester.get()
  end

  def get_timeline_by_user_id(user_id, max_results, opts \\ [])
      when is_binary(user_id) and is_integer(max_results) do
    base_url = "#{@v2}/users/#{user_id}/tweets?max_results=#{max_results}"

    url =
      case opts[:since_id] do
        nil ->
          base_url

        id when is_binary(id) ->
          "#{base_url}&since_id=#{id}"
      end

    url =
      case opts[:tweet_fields] do
        nil ->
          url

        fields when is_list(fields) ->
          fields_url = Enum.map(fields, &to_string(&1)) |> Enum.join(",")
          "#{url}&tweet.fields=#{fields_url}"
      end

    Requester.get(url)
  end
end
