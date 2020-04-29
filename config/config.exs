import Config

config :bitstamp_elixir, Bitstamp.Api.Transport,
  key: "",
  secret: "",
  client_id: "",
  get_recv_timeout: 5000,
  post_recv_timeout: 5000
