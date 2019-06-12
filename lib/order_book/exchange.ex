defmodule OrderBook.Exchange do
  alias OrderBook.{Manager, Instruction}

  def start_link() do
    GenServer.start_link(Manager, [])
  end

  @spec order_book(exchange: pid(), book_depth: integer()) :: list(map())
  def order_book(exchange: exchange_pid, book_depth: book_depth) do
    GenServer.call(exchange_pid, {:view, book_depth})
  end

  @spec send_instruction(exchange: pid(), event: map()) :: {:ok} | {:error, reason: any()}
  def send_instruction(exchange: exchange_pid, event: event) do
    with {:ok, %Instruction{} = instruction} <- Instruction.validate_instruction(event),
         {:ok} <- GenServer.call(exchange_pid, {:send_instruction, instruction}) do
      {:ok}
    else
      {:error, message} -> {:error, reason: message}
    end
  end
end
