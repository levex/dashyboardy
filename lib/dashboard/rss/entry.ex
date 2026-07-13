defmodule Dashboard.Rss.Entry do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rss_entries" do
    field :external_id, :string
    field :title, :string
    field :url, :string
    field :published_at, :utc_datetime
    field :summary, :string
    field :read, :boolean, default: false
    field :saved, :boolean, default: false

    belongs_to :feed, Dashboard.Rss.Feed

    timestamps(type: :utc_datetime)
  end

  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:feed_id, :external_id, :title, :url, :published_at, :summary, :read, :saved])
    |> validate_required([:feed_id, :external_id, :title, :url])
    |> unique_constraint([:feed_id, :external_id])
  end
end
