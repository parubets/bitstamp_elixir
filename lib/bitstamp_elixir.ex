defmodule BitstampElixir do
  use Application

  def start(_, _) do
    import Supervisor.Spec
    opts = [strategy: :one_for_one, name: BitstampElixir.Supervisor]
    Supervisor.start_link([worker(Bitstamp.Api.Transport, [[name: Bitstamp.Api.Transport]])], opts)
  end
end
