defmodule Dashboard.Auth.Credential do
  use Ecto.Schema
  import Ecto.Changeset

  schema "webauthn_credentials" do
    field :credential_id, :string
    field :public_key, :binary
    field :sign_count, :integer, default: 0
    field :label, :string

    belongs_to :user, Dashboard.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(credential, attrs) do
    credential
    |> cast(attrs, [:user_id, :credential_id, :public_key, :sign_count, :label])
    |> validate_required([:user_id, :credential_id, :public_key])
    |> unique_constraint(:credential_id)
  end
end
