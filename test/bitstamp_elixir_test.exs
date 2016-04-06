defmodule BitstampElixirTest do
  use ExUnit.Case
  doctest BitstampElixir

  # Public API

  test "ticker good ticker" do
    {:ok, res} = Bitstamp.Api.ticker
    assert is_map(res) == true
    assert map_size(res) == 9
  end

  # Private API

  test "balance" do
    {:ok, balance} = Bitstamp.Api.balance
    assert is_map(balance) == true
    assert Map.has_key?(balance, "usd_balance")
    assert Map.has_key?(balance, "btc_balance")
    assert Map.has_key?(balance, "fee")
  end

end
