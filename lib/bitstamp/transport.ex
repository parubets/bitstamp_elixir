defmodule Bitstamp.Api.Transport do
  use GenServer

  @base_url "https://www.bitstamp.net/api/"

  ## Public API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def post(method, params) do
    GenServer.call(__MODULE__, {:post, method, params})
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
    res = HTTPotion.post(url, [body: body, headers: ["Content-Type": "application/x-www-form-urlencoded"]])
    case Dict.fetch(res.headers, :"Content-Type") do
      {:ok, "application/json"} ->
        json = parse_json(res)
        {:reply, {:ok, json}, state}
      {:ok, "text/html"} ->
        {:reply, {:error, res.body}, state}
    end
  end

  defp get_api_params do
    nonce = Integer.to_string(:os.system_time(:milli_seconds)) <> "0"
    message = nonce <> Application.get_env(:bitstamp_elixir, :client_id) <> Application.get_env(:bitstamp_elixir, :key)
    signature = :crypto.hmac(:sha256, Application.get_env(:bitstamp_elixir, :secret), message) |> Base.encode16
    {nonce, signature}
  end

  defp parse_json(response) do
    Poison.decode!(response.body)
  end

end
