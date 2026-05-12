defmodule Pluggy.Models.Group do
  alias Pluggy.Models.User

  @collection "groups"

  def all do
    Mongo.find(:mongo, @collection, %{}) |> Enum.to_list()
  end

  def first(id) do
    Mongo.find_one(:mongo, @collection, %{"_id" => BSON.ObjectId.decode!(id)})
  end

  @doc """
  Skapar en grupp med inbäddade användare (embed-mönstret).
  Tar emot `params` från ett HTML-formulär med fält `groupname` och `users[]`.
  """
  def create(params) do
    user_ids = List.wrap(params["users"])

    embedded_users =
      user_ids
      |> Enum.map(&User.first/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.map(fn u -> %{"_id" => u["_id"], "username" => u["username"]} end)

    Mongo.insert_one!(:mongo, @collection, %{
      "groupname" => params["groupname"],
      "users" => embedded_users
    })
  end
end
