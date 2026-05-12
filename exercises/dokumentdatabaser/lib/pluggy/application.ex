defmodule Pluggy.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Mongo, name: :mongo, url: "mongodb://localhost:27017/test"},
      {Plug.Cowboy, scheme: :http, plug: Pluggy.Router, options: [port: 3000]}
    ]

    opts = [strategy: :one_for_one, name: Pluggy.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
