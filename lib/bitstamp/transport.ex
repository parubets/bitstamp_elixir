defmodule Bitstamp.Api.Error do
  defexception message: "Bitstamp API exception"
end

defmodule Bitstamp.Api.Transport do
  use GenServer

  @base_url "https://www.bitstamp.net/api/"
  @bitstamp_client_id Application.get_env(:bitstamp_elixir, :client_id)
  @bitstamp_key Application.get_env(:bitstamp_elixir, :key)
  @bitstamp_secret Application.get_env(:bitstamp_elixir, :secret)

  ## Public API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def get(path) do
    GenServer.call(__MODULE__, {:get, path}, :infinity)
  end

  def post(method, params) do
    GenServer.call(__MODULE__, {:post, method, params}, :infinity)
  end

  ## Server Callbacks

  def init(:ok) do
    {:ok, []}
  end

  def handle_call({:post, method, params}, _from, state) do
    {nonce, signature} = get_api_params
    url = @base_url <> method <> "/"
    body = Dict.merge(%{key: get_bitstamp_key, signature: signature, nonce: nonce}, params)
      |> URI.encode_query
    post_headers = %{"Content-Type": "application/x-www-form-urlencoded"}
    case HTTPoison.post(url, body, post_headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body, headers: headers}} ->
        reply = parse_res(body, headers)
        {:reply, reply, state}
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        raise "Not found :("
      {:error, e} ->
        {:reply, {:error, e}, state}
    end
  end

  def handle_call({:get, path}, _from, state) do
    url = @base_url <> path <> "/"
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body, headers: headers}} ->
        reply = parse_res(body, headers)
        {:reply, reply, state}
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        raise "Not found :("
      {:error, e} ->
        {:reply, {:error, e}, state}
    end
  end

  defp parse_res(body, headers) do
    case get_header(headers, "Content-Type") do
      "application/json" ->
        json = parse_json(body)
        case json do
          %{"status" => "error", "reason" => reason} ->
            {:error, %Bitstamp.Api.Error{message: reason}}
          _ ->
            {:ok, json}
        end
      _ ->
        {:error, %Bitstamp.Api.Error{message: body}}
    end
  end

  defp get_api_params do
    nonce = Integer.to_string(:os.system_time(:milli_seconds)) <> "0"
    message = nonce <> get_bitstamp_client_id <> get_bitstamp_key
    signature = :crypto.hmac(:sha256, get_bitstamp_secret, message) |> Base.encode16
    {nonce, signature}
  end

  defp parse_json(body) do
    Poison.decode!(body)
  end

  defp get_header(headers, key) do
    headers
    |> Enum.filter(fn({k, _}) -> k == key end)
    |> hd
    |> elem(1)
  end

  defp get_bitstamp_client_id do
    Application.get_env(:bitstamp_elixir, :client_id) || System.get_env("BITSTAMP_CLIENT_ID") || @bitstamp_client_id
  end

  defp get_bitstamp_key do
    Application.get_env(:bitstamp_elixir, :key) || System.get_env("BITSTAMP_KEY") || @bitstamp_key
  end

  defp get_bitstamp_secret do
    Application.get_env(:bitstamp_elixir, :secret) || System.get_env("BITSTAMP_SECRET") || @bitstamp_secret
  end

end
