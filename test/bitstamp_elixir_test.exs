defmodule BitstampElixirTest do
  use ExUnit.Case
  doctest BitstampElixir

  test "ticker good ticker" do
    {:ok, res} = Bitstamp.Api.ticker
    assert is_map(res) == true
    assert map_size(res) == 9
  end

end
