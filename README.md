# OrderBook

Simple solution to simulate a simplified model of an order book of a financial exchange

Valid input example:

```
%{
	instruction: :new | :update | :delete,
	side: :bid | :ask,
	price_level_index: interger()
	price: float()
	quantity: integer()
}
```

# Design decisions

- ETS table was an interesting for this use case, because it has built-in features like ordered-set that behaves exactly like it is required in this problem. And you also get for free concurrency read/write capabilities.

- GenServer "manages" and protects access to the ets table, in a production environment would be necessary to supervise this GenServer and also think of more scenarios if it was really supposed to be used for concurrency.

- All main features are test covered!

- The GenServer looks a little messy, but that's because GenServer and specially ETS have some weird syntax, maybe I could abstract something more but I didn't want to overthink it (better duplicated code than wrong abstraction).