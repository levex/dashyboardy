defmodule Dashboard.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :name, :string
    field :google_id, :string

    has_one :widget_layout, Dashboard.Widgets.Layout

    timestamps(type: :utc_datetime)
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :name, :google_id])
    |> validate_required([:email, :google_id])
    |> unique_constraint(:email)
    |> unique_constraint(:google_id)
  end
end
