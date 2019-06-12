defmodule OrderBook.Manager do
  use GenServer
  @compile {:parse_transform, :ms_transform}

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
           instruction: :new,
           side: :ask,
           price_level_index: price_level_index,
           price: price,
           quantity: quantity
         }},
        _from,
        state
      ) do
    new_value =
      case :ets.lookup(@tab, price_level_index) do
        [
          {_price_level_index,
           %{
             ask_price: _ask_price,
             ask_quantity: _ask_qt,
             bid_price: bid_price,
             bid_quantity: bid_qt
           }}
        ] ->
          %{ask_price: price, ask_quantity: quantity, bid_price: bid_price, bid_quantity: bid_qt}

        _ ->
          %{ask_price: price, ask_quantity: quantity, bid_price: 0.0, bid_quantity: 0}
      end

    :ets.insert(@tab, {price_level_index, new_value})
    {:reply, {:ok}, state}
  end

  def handle_call(
        {:send_instruction,
         %Instruction{
           instruction: :new,
           side: :bid,
           price_level_index: price_level_index,
           price: price,
           quantity: quantity
         }},
        _from,
        state
      ) do
    new_value =
      case :ets.lookup(@tab, price_level_index) do
        [
          {_price_level_index,
           %{
             ask_price: ask_price,
             ask_quantity: ask_qt,
             bid_price: _bid_price,
             bid_quantity: _bid_qt
           }}
        ] ->
          %{ask_price: ask_price, ask_quantity: ask_qt, bid_price: price, bid_quantity: quantity}

        _ ->
          %{ask_price: 0.0, ask_quantity: 0, bid_price: price, bid_quantity: quantity}
      end

    :ets.insert(@tab, {price_level_index, new_value})
    {:reply, {:ok}, state}
  end

  def handle_call(
        {:send_instruction,
         %Instruction{
           instruction: :update,
           side: :bid,
           price_level_index: price_level_index,
           price: price,
           quantity: quantity
         }},
        _from,
        state
      ) do
    case :ets.lookup(@tab, price_level_index) do
      [
        {_price_level_index,
         %{
           ask_price: ask_price,
           ask_quantity: ask_qt,
           bid_price: _bid_price,
           bid_quantity: _bid_qt
         }}
      ] ->
        :ets.insert(
          @tab,
          {price_level_index,
           %{
             ask_price: ask_price,
             ask_quantity: ask_qt,
             bid_price: price,
             bid_quantity: quantity
           }}
        )

        {:reply, {:ok}, state}

      _ ->
        {:reply, {:error, "Unexisting record to update"}, state}
    end
  end

  def handle_call(
        {:send_instruction,
         %Instruction{
           instruction: :update,
           side: :ask,
           price_level_index: price_level_index,
           price: price,
           quantity: quantity
         }},
        _from,
        state
      ) do
    case :ets.lookup(@tab, price_level_index) do
      [
        {_price_level_index,
         %{
           ask_price: _ask_price,
           ask_quantity: _ask_qt,
           bid_price: bid_price,
           bid_quantity: bid_qt
         }}
      ] ->
        :ets.insert(
          @tab,
          {price_level_index,
           %{
             ask_price: price,
             ask_quantity: quantity,
             bid_price: bid_price,
             bid_quantity: bid_qt
           }}
        )

        {:reply, {:ok}, state}

      _ ->
        {:reply, {:error, "Unexisting record to update"}, state}
    end
  end

  def handle_call(
        {:send_instruction,
         %Instruction{
           instruction: :delete,
           price_level_index: price_level_index
         }},
        _from,
        state
      ) do
    :ets.delete(@tab, price_level_index)

    {:reply, {:ok}, state}
  end

  def handle_call({:view, book_depth}, _from, state) do
    filter_fun =
      :ets.fun2ms(fn {price_level_index, index_data} when price_level_index <= book_depth ->
        index_data
      end)

    result = :ets.select(@tab, filter_fun)

    {:reply, result, state}
  end
end
