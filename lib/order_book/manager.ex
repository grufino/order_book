defmodule OrderBook.Manager do
  use GenServer

  alias OrderBook.Instruction

  @tab :order_book

  def init(_) do
    :ets.new(@tab, [
      :ordered_set,
      :named_table,
      :protected,
      read_concurrency: true,
      write_concurrency: true
    ])

    {:ok, %{}}
  end

  def handle_call(
        {:send_instruction,
         %Instruction{
           instruction: :insert,
           side: side,
           price_level_index: price_level_index,
           price: price,
           quantity: quantity
         }},
        state
      ) do
    :ets.insert(@tab, {{price_level_index, side}, price, quantity})
    {:reply, :ok}
  end

  def handle_call(
        {:send_instruction,
         %Instruction{
           instruction: :update,
           side: side,
           price_level_index: price_level_index,
           price: price,
           quantity: quantity
         }},
        state
      ) do
    response =
      if :ets.lookup(@tab, {price_level_index, :bid}) != [] or
           :ets.lookup(@tab, {price_level_index, :ask}) != [] do
        :ets.insert(@tab, {{price_level_index, side}, price, quantity})
        :ok
      else
        {:error, "Unexisting record to update"}
      end

    {:reply, response, state}
  end

  def handle_call(
        {:send_instruction,
         %Instruction{
           instruction: :delete,
           price_level_index: price_level_index
         }},
        state
      ) do
    :ets.delete(@tab, {price_level_index, :bid})
    :ets.delete(@tab, {price_level_index, :ask})

    {:reply, :ok, state}
  end

  def handle_call(:view, _from, state) do
    {:reply, :ets.tab2list(@tab), state}
  end
end
