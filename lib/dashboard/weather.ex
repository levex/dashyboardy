defmodule Dashboard.Weather do
  @moduledoc """
  Weather reading storage for configured cities.
  """

  import Ecto.Query
  alias Dashboard.Repo
  alias Dashboard.Weather.Reading

  @cities ["Budapest", "Szeged"]

  def cities, do: @cities

  def insert_reading(attrs) do
    %Reading{}
    |> Reading.changeset(attrs)
    |> Repo.insert()
  end

  def latest_by_city do
    @cities
    |> Enum.map(fn city ->
      reading =
        Reading
        |> where([r], r.city == ^city)
        |> order_by([r], desc: r.recorded_at)
        |> limit(1)
        |> Repo.one()

      {city, reading}
    end)
    |> Map.new()
  end

  def delete_older_than(days) do
    cutoff = DateTime.utc_now() |> DateTime.add(-days * 24 * 60 * 60, :second)

    from(r in Reading, where: r.recorded_at < ^cutoff)
    |> Repo.delete_all()
  end
end
