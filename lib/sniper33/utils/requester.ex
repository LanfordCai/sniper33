defmodule Sniper33.Utils.Requester do
  @moduledoc false

  @type retry_opts :: [retries: integer(), interval: integer()]
  @type error_code :: integer()

  @callback get(url :: String.t()) ::
              {:ok, term()} | {:resp_error, term()} | {:error, error_code(), term()}
  @callback get(url :: String.t(), retry_opts :: retry_opts()) ::
              {:ok, term()} | {:resp_error, term()} | {:error, error_code(), term()}
  @callback post(url :: String.t(), body :: map()) ::
              {:ok, term()} | {:resp_error, term()} | {:error, error_code(), term()}
  @callback post(url :: String.t(), body :: map(), retry_opts :: retry_opts()) ::
              {:ok, term()} | {:resp_error, term()} | {:error, error_code(), term()}

  defmacro __using__(_opts) do
    quote do
      require Logger

      @behaviour Sniper33.Utils.Requester

      def get(url, opts \\ []) do
        retry_request(:get, url, %{}, opts)
      end

      def post(url, body, opts \\ []) do
        retry_request(:post, url, body, opts)
      end

      def rpc_call(url, body, opts \\ []) do
        body =
          if is_list(body) do
            body
            |> Enum.with_index()
            |> Enum.map(fn {query, index} ->
              Map.merge(query, %{id: index + 1, jsonrpc: "2.0"})
            end)
          else
            Map.merge(body, %{id: 1, jsonrpc: "2.0"})
          end

        retry_request(:post, url, body, opts)
      end

      defp retry_request(method, url, body, opts) do
        func = fn ->
          method
          |> request(url, body, opts)
          |> (fn x ->
                debug(x)
                x
              end).()
          |> handle_response()
        end

        retries = opts[:retries] || retry_settings()[:retries]
        interval = opts[:interval] || retry_settings()[:interval]
        adjusted_opts = [retries: retries, interval: interval]

        retry_or_return(func.(), func, adjusted_opts)
      end

      def request(:get, url, _, opts) do
        options = if Enum.empty?(opts), do: request_options(), else: opts
        HTTPoison.get(url, (options[:headers] || []) ++ request_headers(:get), options)
      end

      def request(:post, url, body, opts) do
        options = if Enum.empty?(opts), do: request_options(), else: opts
        headers = opts[:headers] || request_headers(:post)

        if :binary in (options[:tags] || []) do
          HTTPoison.post(
            url,
            body,
            options[:headers] || [],
            options
          )
        else
          HTTPoison.post(
            url,
            Jason.encode!(body),
            (options[:headers] || []) ++ request_headers(:post),
            options
          )
        end
      end

      defp handle_response(_), do: raise("handle_response/1 not implemented")
      defp request_options, do: raise("request_options/0 not implemented")
      defp retry_settings, do: [retries: 3, interval: 2]

      defp request_headers(_method) do
        [{"Content-Type", "application/json"}]
      end

      defp retry_or_return({:ok, result}, _func, _retry_opts), do: {:ok, result}

      defp retry_or_return({:error, code, message} = error, _func, _retry_opts) do
        log_warn(error)
        error
      end

      defp retry_or_return({:resp_error, reason} = error, _func, retries: 0, interval: _interval) do
        log_warn(error)
        error
      end

      defp retry_or_return({:resp_error, _error}, func, retries: retries, interval: interval) do
        Process.sleep(interval * 1000)
        retry_or_return(func.(), func, retries: retries - 1, interval: interval)
      end

      defp log_warn(content) do
        Logger.warn("[#{requester_name()}] #{inspect(content)}")
      end

      defp requester_name do
        __MODULE__
        |> Module.split()
        |> Enum.reject(&(&1 in ~w(Elixir Venezia Blockchain Chain)))
        |> Enum.join()
      end

      defp debug(_), do: nil

      defoverridable handle_response: 1,
                     retry_settings: 0,
                     request_options: 0,
                     request_headers: 1,
                     debug: 1
    end
  end

  @doc """
  Handle common http json response.

  Set `ignore_status: true` to get the decoded body while status code isn't 200.
  """
  def handle_response(resp, opts \\ [])

  def handle_response(
        resp = {:ok, %HTTPoison.Response{status_code: status, body: body}},
        opts
      )
      when body != "" do
    cond do
      opts[:ignore_status] != true and status != 200 ->
        {:resp_error, {:unknown_error, resp}}

      true ->
        case Jason.decode(body) do
          {:ok, body} ->
            {:ok, body}

          error ->
            {:resp_error, {:decode_error, error}}
        end
    end
  end

  def handle_response(error, _opts) do
    {:resp_error, {:unknown_error, error}}
  end
end
