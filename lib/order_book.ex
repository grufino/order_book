defmodule OrderBook do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      supervisor(UrlShortener.UrlManager, [])
    ]

    opts = [strategy: :one_for_one, name: UrlShortener.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
