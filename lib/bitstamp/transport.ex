defmodule Bitstamp.Api.Error do
  defexception [message: "Bitstamp API exception", body: nil, status_code: nil, headers: nil]
end

defmodule Bitstamp.Api.Transport do
  use GenServer

  @base_url "https://www.bitstamp.net/api/"
  @bitstamp_client_id Application.get_env(:bitstamp_elixir, __MODULE__, []) |> Keyword.get(:client_id)
  @bitstamp_key Application.get_env(:bitstamp_elixir, __MODULE__, []) |> Keyword.get(:key)
  @bitstamp_secret Application.get_env(:bitstamp_elixir, __MODULE__, []) |> Keyword.get(:secret)

  @default_get_recv_timeout 5_000
  @default_post_recv_timeout 5_000

  ## Public API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def get(path) do
    GenServer.call(Bitstamp.Api.GetTransport, {:get, path}, :infinity)
  end

  def post(method, params) do
    GenServer.call(Bitstamp.Api.PostTransport, {:post, method, params}, :infinity)
  end

  ## Server Callbacks

  def init(:ok) do
    {:ok, []}
  end

  def handle_call({:post, method, params}, _from, state) do
    {nonce, signature} = get_api_params()
    url = @base_url <> method <> "/"
    body = Map.merge(%{key: get_bitstamp_key(), signature: signature, nonce: nonce}, params)
      |> URI.encode_query
    post_headers = %{"Content-Type": "application/x-www-form-urlencoded"}
    opts = [recv_timeout: (config(:post_recv_timeout) || @default_post_recv_timeout)]
    case HTTPoison.post(url, body, post_headers, opts) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body, headers: headers}} ->
        reply = parse_res(body, headers)
        {:reply, reply, state}
      {:ok, %HTTPoison.Response{status_code: status_code, body: body, headers: headers}} ->
        {:reply, {:error, %Bitstamp.Api.Error{message: "Bitstamp POST API exception", body: body, status_code: status_code, headers: headers}}, state}
      {:error, e} ->
        {:reply, {:error, e}, state}
    end
  end

  def handle_call({:get, path}, from, state) do
    url = @base_url <> path <> "/"
    opts = [recv_timeout: (config(:get_recv_timeout) || @default_get_recv_timeout)]
    me = self()
    Task.start fn ->
      reply = case HTTPoison.get(url, opts) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body, headers: headers}} ->
          parse_res(body, headers)
        {:ok, %HTTPoison.Response{status_code: status_code, body: body, headers: headers}} ->
          {:error, %Bitstamp.Api.Error{message: "Bitstamp GET API exception", body: body, status_code: status_code, headers: headers}}
        {:error, e} ->
          {:error, e}
      end
      send me, {:got_get, reply, from}
    end
    {:noreply, state}
  end

  def handle_info({:got_get, reply, from}, state) do
    GenServer.reply(from, reply)
    {:noreply, state}
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
    message = nonce <> get_bitstamp_client_id() <> get_bitstamp_key()
    signature = :crypto.hmac(:sha256, get_bitstamp_secret(), message) |> Base.encode16
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
    vault_get_kv("bitstamp", "client_id") || config(:client_id) || System.get_env("BITSTAMP_CLIENT_ID") || @bitstamp_client_id
  end

  defp get_bitstamp_key do
    vault_get_kv("bitstamp", "key") || config(:key) || System.get_env("BITSTAMP_KEY") || @bitstamp_key
  end

  defp get_bitstamp_secret do
    vault_get_kv("bitstamp", "secret") || config(:secret) || System.get_env("BITSTAMP_SECRET") || @bitstamp_secret
  end

  defp vault_get_kv(path, key) do
    case config(:vault_module) do
      vault_mod when is_atom(vault_mod) -> vault_mod.get_kv(path, key)
      _ -> nil
    end
  end

  defp config do
    Application.get_env(:bitstamp_elixir, __MODULE__, [])
  end

  defp config(key, default \\ nil) do
    Keyword.get(config(), key, default)
  end

end
