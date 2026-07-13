defmodule Dashboard.Weather.Reading do
  use Ecto.Schema
  import Ecto.Changeset

  schema "weather_readings" do
    field :city, :string
    field :temperature, :float
    field :conditions, :string
    field :humidity, :integer
    field :metadata, :map, default: %{}
    field :recorded_at, :utc_datetime

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(reading, attrs) do
    reading
    |> cast(attrs, [:city, :temperature, :conditions, :humidity, :metadata, :recorded_at])
    |> validate_required([:city, :recorded_at])
  end
end
