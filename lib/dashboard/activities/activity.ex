defmodule Dashboard.Activities.Activity do
  use Ecto.Schema
  import Ecto.Changeset

  schema "activities" do
    field :source, :string
    field :source_instance, :string
    field :external_id, :string
    field :type, :string
    field :title, :string
    field :summary, :string
    field :author, :string
    field :url, :string
    field :occurred_at, :utc_datetime
    field :metadata, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  def changeset(activity, attrs) do
    activity
    |> cast(attrs, [
      :source,
      :source_instance,
      :external_id,
      :type,
      :title,
      :summary,
      :author,
      :url,
      :occurred_at,
      :metadata
    ])
    |> validate_required([
      :source,
      :source_instance,
      :external_id,
      :type,
      :title,
      :occurred_at
    ])
    |> unique_constraint([:source, :source_instance, :external_id])
  end
end
