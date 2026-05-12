defmodule Pluggy.Router do
  use Plug.Router

  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart],
    pass: ["*/*"]

  plug :match
  plug :dispatch

  get "/" do
    conn
    |> Plug.Conn.put_resp_header("location", "/users")
    |> Plug.Conn.send_resp(302, "")
  end

  forward "/users", to: Pluggy.Controllers.Users
  forward "/groups", to: Pluggy.Controllers.Groups

  match _ do
    send_resp(conn, 404, "Not found")
  end
end
