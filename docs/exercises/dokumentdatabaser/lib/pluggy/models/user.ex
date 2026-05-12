defmodule Pluggy.Models.User do
  @collection "users"

  def all do
    Mongo.find(:mongo, @collection, %{}) |> Enum.to_list()
  end

  def first(id) do
    Mongo.find_one(:mongo, @collection, %{"_id" => BSON.ObjectId.decode!(id)})
  end

  def create(params) do
    Mongo.insert_one!(:mongo, @collection, clean(params))
  end

  def update(id, params) do
    Mongo.update_one(:mongo, @collection,
      %{"_id" => BSON.ObjectId.decode!(id)},
      %{"$set" => clean(params)})
  end

  defp clean(params) do
    params
    |> Map.drop(["id", "_id"])
  end
end
