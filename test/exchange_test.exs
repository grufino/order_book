defmodule ExchangeTest do
  use ExUnit.Case, async: false

  alias OrderBook.Exchange

  setup do
    {:ok, pid} = Exchange.start_link()
    %{exchange_pid: pid}
  end

  def new_instruction(side \\ Enum.random([:bid, :ask])) do
    %{
      instruction: :new,
      side: side,
      price_level_index: Enum.random(1..100),
      # cast to float
      price: Enum.random(1..100) / 1,
      quantity: Enum.random(1..100)
    }
  end

  test "insert and get", %{exchange_pid: pid} do
    instruction = new_instruction(:bid)
    assert {:ok} = Exchange.send_instruction(exchange: pid, event: instruction)

    assert Exchange.order_book(exchange: pid, book_depth: instruction.price_level_index) == [
             %{
               ask_price: 0,
               ask_quantity: 0,
               bid_price: instruction.price,
               bid_quantity: instruction.quantity
             }
           ]
  end

  test "insert update and get updated", %{exchange_pid: pid} do
    instruction_1 = new_instruction(:bid)

    instruction_2 = %{
      instruction: :update,
      side: :ask,
      price_level_index: instruction_1.price_level_index,
      price: Enum.random(1..100) / 1,
      quantity: Enum.random(1..100)
    }

    assert {:ok} = Exchange.send_instruction(exchange: pid, event: instruction_1)
    assert {:ok} = Exchange.send_instruction(exchange: pid, event: instruction_2)

    assert Exchange.order_book(exchange: pid, book_depth: instruction_1.price_level_index) == [
             %{
               ask_price: instruction_2.price,
               ask_quantity: instruction_2.quantity,
               bid_price: instruction_1.price,
               bid_quantity: instruction_1.quantity
             }
           ]
  end

  test "view all records after list insertion ordered with unordered list", %{exchange_pid: pid} do
    reversed_instructions =
      1..20
      |> Enum.reverse()
      |> Enum.map(fn price_level_index ->
        instruction = %{
          instruction: :new,
          side: :bid,
          price_level_index: price_level_index,
          price: Enum.random(1..100) / 1,
          quantity: Enum.random(1..100)
        }
      end)

    Enum.each(reversed_instructions, fn instruction ->
      Exchange.send_instruction(exchange: pid, event: instruction)
    end)

    order_book = Exchange.order_book(exchange: pid, book_depth: 20)

    last_instruction = List.last(reversed_instructions)

    first_order = List.first(order_book)

    # Because index order is maintained, last in reversed instructions become first in order book

    assert last_instruction.price == first_order.bid_price
    assert last_instruction.quantity == first_order.bid_quantity
  end

  test "delete maintains order", %{exchange_pid: pid} do
    reversed_instructions =
      1..20
      |> Enum.reverse()
      |> Enum.map(fn price_level_index ->
        instruction = %{
          instruction: :new,
          side: :bid,
          price_level_index: price_level_index,
          price: Enum.random(1..100) / 1,
          quantity: Enum.random(1..100)
        }
      end)

    Enum.each(reversed_instructions, fn instruction ->
      Exchange.send_instruction(exchange: pid, event: instruction)
    end)

    Exchange.send_instruction(
      exchange: pid,
      event: %{instruction: :delete, price_level_index: 19}
    )

    order_book = Exchange.order_book(exchange: pid, book_depth: 19)

    last_instruction = List.last(reversed_instructions)

    first_order = List.first(order_book)

    # After delete, 20 is shifted down to position 19, becoming last element maintaining order

    assert last_instruction.price == first_order.bid_price
    assert last_instruction.quantity == first_order.bid_quantity
  end

  test "update unexisting error", %{exchange_pid: pid} do
    instruction = %{
      instruction: :update,
      side: :ask,
      price_level_index: 9999,
      price: Enum.random(1..100) / 1,
      quantity: Enum.random(1..100)
    }

    assert Exchange.send_instruction(exchange: pid, event: instruction) ==
             {:error, reason: "Unexisting record to update"}
  end

  test "invalid input error", %{exchange_pid: pid} do
    instruction = %{
      instruction: :update,
      side: :ask,
      price_level_index: "invalid",
      price: 123.1,
      quantity: 1
    }

    assert Exchange.send_instruction(exchange: pid, event: instruction) ==
             {:error,
              [
                reason:
                  "Malformed Input: %{instruction: :update, price: 123.1, price_level_index: \"invalid\", quantity: 1, side: :ask}"
              ]}
  end

  test "exercise example", %{exchange_pid: pid} do
    assert {:ok} =
             Exchange.send_instruction(
               exchange: pid,
               event: %{
                 instruction: :new,
                 side: :bid,
                 price_level_index: 1,
                 price: 50.0,
                 quantity: 30
               }
             )

    assert {:ok} =
             Exchange.send_instruction(
               exchange: pid,
               event: %{
                 instruction: :new,
                 side: :bid,
                 price_level_index: 2,
                 price: 40.0,
                 quantity: 40
               }
             )

    assert {:ok} =
             Exchange.send_instruction(
               exchange: pid,
               event: %{
                 instruction: :new,
                 side: :ask,
                 price_level_index: 1,
                 price: 60.0,
                 quantity: 10
               }
             )

    assert {:ok} =
             Exchange.send_instruction(
               exchange: pid,
               event: %{
                 instruction: :new,
                 side: :ask,
                 price_level_index: 2,
                 price: 70.0,
                 quantity: 10
               }
             )

    assert {:ok} =
             Exchange.send_instruction(
               exchange: pid,
               event: %{
                 instruction: :update,
                 side: :ask,
                 price_level_index: 2,
                 price: 70.0,
                 quantity: 20
               }
             )

    assert {:ok} =
             Exchange.send_instruction(
               exchange: pid,
               event: %{
                 instruction: :update,
                 side: :bid,
                 price_level_index: 1,
                 price: 50.0,
                 quantity: 40
               }
             )

    assert Exchange.order_book(exchange: pid, book_depth: 2) == [
             %{ask_price: 60.0, ask_quantity: 10, bid_price: 50.0, bid_quantity: 40},
             %{ask_price: 70.0, ask_quantity: 20, bid_price: 40.0, bid_quantity: 40}
           ]
  end
end
