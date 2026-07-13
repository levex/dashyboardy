defmodule Dashboard.Widgets.Layout do
  use Ecto.Schema
  import Ecto.Changeset

  schema "widget_layouts" do
    field :layout, :map, default: %{}

    belongs_to :user, Dashboard.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(layout, attrs) do
    layout
    |> cast(attrs, [:user_id, :layout])
    |> validate_required([:user_id, :layout])
    |> unique_constraint(:user_id)
  end
end
