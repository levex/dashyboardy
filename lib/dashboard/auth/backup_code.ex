defmodule Dashboard.Auth.BackupCode do
  use Ecto.Schema
  import Ecto.Changeset

  schema "backup_codes" do
    field :code_hash, :string
    field :used_at, :utc_datetime

    belongs_to :user, Dashboard.Accounts.User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(backup_code, attrs) do
    backup_code
    |> cast(attrs, [:user_id, :code_hash, :used_at])
    |> validate_required([:user_id, :code_hash])
  end
end
