defmodule OrderBook.Exchange do
  alias OrderBook.Manager

  def start_link() do
    Manager.init(:ok)
  end
end
