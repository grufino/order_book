defmodule OrderBook.Instruction do
  alias OrderBook.Instruction

  @enforce_keys [:instruction, :price_level_index]
  defstruct instruction: :new,
            side: :bid,
            price_level_index: 1,
            price: 50.0,
            quantity: 30

  @upsert_instructions [:new, :update]
  @valid_sides [:bid, :ask]

  def validate_instruction(
        %Instruction{
          instruction: instruction_type,
          side: side,
          price_level_index: price_level_index,
          price: price,
          quantity: quantity
        } = instruction
      )
      when instruction_type in @upsert_instructions and side in @valid_sides and
             quantity > 0 and price_level_index > 0 and price > 0 and is_integer(quantity) and
             is_integer(price_level_index) do
    {:ok, instruction}
  end

  def validate_instruction(
        %Instruction{
          instruction: :delete,
          price_level_index: price_level_index
        } = instruction
      )
      when price_level_index > 0 do
    {:ok, instruction}
  end

  def validate_instruction(input) do
    {:error, input}
  end
end
