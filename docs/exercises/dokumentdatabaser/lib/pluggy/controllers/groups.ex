defmodule Pluggy.Controllers.Groups do
  use Plug.Router
  alias Pluggy.{Models, View}

  plug :match
  plug :dispatch

  get "/" do
    body =
      View.render("groups/index.html.eex",
        groups: Models.Group.all(),
        users: Models.User.all()
      )

    send_html(conn, body)
  end

  post "/" do
    Models.Group.create(conn.params)
    redirect(conn, "/groups")
  end

  get "/:id" do
    body = View.render("groups/show.html.eex", group: Models.Group.first(id))
    send_html(conn, body)
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
