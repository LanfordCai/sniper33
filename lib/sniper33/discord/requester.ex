defmodule Sniper33.Discord.Requester do
  @moduledoc false

  use Sniper33.Utils.Requester

  defp retry_settings, do: [retries: 3, interval: 2]

  defp request_options,
    do: [
      hackney: [recv_timeout: 8000],
      ssl: [{:versions, [:"tlsv1.2"]}]
    ]

  defp request_headers(:get) do
    [
      {"Accept", "application/json"}
    ]
  end

  defp request_headers(:post) do
    [
      {"Accept", "application/json"},
      {"Content-Type", "application/json"}
    ]
  end

  defp handle_response({:ok, %{status_code: status_code, body: ""}})
       when status_code < 300 and status_code >= 200,
       do: {:ok, nil}

  defp handle_response({:ok, %{status_code: status_code, body: body}})
       when status_code < 300 and status_code >= 200 do
    case Jason.decode(body) do
      {:ok, decoded_body} ->
        handle_ok_response(decoded_body)

      _otherwise ->
        Logger.error("[#{__MODULE__}] decode_failed! body: #{body}, code: #{status_code}")
        {:resp_error, :decode_failed}
    end
  end

  defp handle_response({:ok, %{status_code: status_code, body: body}}) do
    case Jason.decode(body) do
      {:ok, %{"error" => msg}} ->
        {:error, -1, msg}

      _otherwise ->
        Logger.error("[#{__MODULE__}] decode_failed! body: #{body}, code: #{status_code}")
        {:resp_error, :decode_failed}
    end
  end

  defp handle_response({:error, %{reason: reason}}), do: {:resp_error, reason}

  defp handle_ok_response(resp) do
    {:ok, resp}
  end
end
