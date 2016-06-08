defmodule Bitstamp.Api do

  def eur_usd do
    get_from_api "eur_usd"
  end

  def ticker do
    get_from_api "ticker"
  end

  def ticker_usd do
    get_from_api "v2/ticker/btcusd"
  end

  def ticker_eur do
    get_from_api "v2/ticker/btceur"
  end

  def orderbook do
    get_from_api "order_book"
  end

  def orderbook_usd do
    get_from_api "v2/order_book/btcusd"
  end

  def orderbook_eur do
    get_from_api "v2/order_book/btceur"
  end

  def balance do
    post_to_api "v2/balance"
  end

  def user_transactions do
    post_to_api "user_transactions"
  end

  def user_transactions(opts) do
    offset = Keyword.get(opts, :offset, 0)
    limit = Keyword.get(opts, :limit, 100)
    sort = Keyword.get(opts, :sort, "desc")
    post_to_api "user_transactions", %{offset: offset, limit: limit, sort: sort}
  end

  def open_orders do
    post_to_api "open_orders"
  end

  def open_orders_usd do
    post_to_api "v2/open_orders/btcusd"
  end

  def open_orders_eur do
    post_to_api "v2/open_orders/btceur"
  end

  def order_status(order_id) do
    post_to_api "order_status", %{id: order_id}
  end

  def cancel_order(order_id) do
    post_to_api "cancel_order", %{id: order_id}
  end

  def cancel_all_orders do
    post_to_api "cancel_all_orders"
  end

  def buy(opts) do
    create_order("buy", opts)
  end

  def buy_usd(opts) do
    create_order("v2/buy/btcusd", opts)
  end

  def buy_eur(opts) do
    create_order("v2/buy/btceur", opts)
  end

  def sell(opts) do
    create_order("sell", opts)
  end

  def sell_usd(opts) do
    create_order("v2/sell/btcusd", opts)
  end

  def sell_eur(opts) do
    create_order("v2/sell/btceur", opts)
  end

  def withdrawal_requests do
    post_to_api "withdrawal_requests"
  end

  def bitcoin_withdrawal(opts) do
    amount = Keyword.fetch!(opts, :amount)
    address = Keyword.fetch!(opts, :address)
    post_to_api "bitcoin_withdrawal", %{amount: amount, address: address}
  end

  def bitcoin_deposit_address do
    post_to_api "bitcoin_deposit_address"
  end

  def unconfirmed_btc do
    post_to_api "unconfirmed_btc"
  end

  def ripple_withdrawal(opts) do
    amount = Keyword.fetch!(opts, :amount)
    address = Keyword.fetch!(opts, :address)
    currency = Keyword.fetch!(opts, :currency)
    post_to_api "ripple_withdrawal", %{amount: amount, address: address, currency: currency}
  end

  def ripple_address do
    post_to_api "ripple_address"
  end

  defp create_order(action, opts) do
    amount = Keyword.fetch!(opts, :amount)
    price = Keyword.fetch!(opts, :price)
    case Keyword.fetch(opts, :limit_price) do
      {:ok, limit_price} ->
        post_to_api action, %{amount: amount, price: price, limit_price: limit_price}
      _ ->
        post_to_api action, %{amount: amount, price: price}
    end
  end

  defp get_from_api(path) do
    Bitstamp.Api.Transport.get(path)
  end

  defp post_to_api(method, params \\ %{}) do
    Bitstamp.Api.Transport.post(method, params)
  end

end
