defmodule Bitstamp.Api.Error do
  defexception message: "Bitstamp API exception"
end

defmodule Bitstamp.Api.Transport do
  use GenServer

  @base_url "https://www.bitstamp.net/api/"

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
    body = Dict.merge(%{key: Application.get_env(:bitstamp_elixir, :key), signature: signature, nonce: nonce}, params)
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
        {:ok, json}
      _ ->
        {:error, %Bitstamp.Api.Error{message: body}}
    end
  end

  defp get_api_params do
    nonce = Integer.to_string(:os.system_time(:milli_seconds)) <> "0"
    message = nonce <> Application.get_env(:bitstamp_elixir, :client_id) <> Application.get_env(:bitstamp_elixir, :key)
    signature = :crypto.hmac(:sha256, Application.get_env(:bitstamp_elixir, :secret), message) |> Base.encode16
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

end
