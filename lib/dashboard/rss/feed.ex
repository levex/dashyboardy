defmodule Dashboard.Rss.Feed do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rss_feeds" do
    field :name, :string
    field :url, :string
    field :enabled, :boolean, default: true

    has_many :entries, Dashboard.Rss.Entry

    timestamps(type: :utc_datetime)
  end

  def changeset(feed, attrs) do
    feed
    |> cast(attrs, [:name, :url, :enabled])
    |> validate_required([:name, :url])
    |> unique_constraint(:url)
  end
end
