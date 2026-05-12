defmodule Pluggy.Controllers.Users do
  use Plug.Router
  alias Pluggy.{Models, View}

  plug :match
  plug :dispatch

  get "/" do
    body = View.render("users/index.html.eex", users: Models.User.all())
    send_html(conn, body)
  end

  post "/" do
    Models.User.create(conn.params)
    redirect(conn, "/users")
  end

  get "/:id" do
    body = View.render("users/show.html.eex", user: Models.User.first(id))
    send_html(conn, body)
  end

  post "/:id" do
    Models.User.update(id, conn.params)
    redirect(conn, "/users/#{id}")
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end

  defp send_html(conn, body) do
    conn
    |> Plug.Conn.put_resp_content_type("text/html")
    |> Plug.Conn.send_resp(200, body)
  end

  defp redirect(conn, path) do
    conn
    |> Plug.Conn.put_resp_header("location", path)
    |> Plug.Conn.send_resp(302, "")
  end
end
