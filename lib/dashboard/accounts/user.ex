defmodule Dashboard.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :display_name, :string, default: "Owner"
    field :user_handle, :binary

    has_one :widget_layout, Dashboard.Widgets.Layout
    has_many :credentials, Dashboard.Auth.Credential
    has_many :backup_codes, Dashboard.Auth.BackupCode

    timestamps(type: :utc_datetime)
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:display_name, :user_handle])
    |> validate_required([:display_name, :user_handle])
  end
end
