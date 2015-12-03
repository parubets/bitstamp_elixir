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
    json = parse_json(res)
    {:reply, json, state}
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
