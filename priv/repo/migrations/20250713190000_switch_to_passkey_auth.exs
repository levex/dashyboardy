defmodule Dashboard.Repo.Migrations.SwitchToPasskeyAuth do
  use Ecto.Migration

  def change do
    create table(:webauthn_credentials) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :credential_id, :string, null: false
      add :public_key, :binary, null: false
      add :sign_count, :integer, default: 0, null: false
      add :label, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:webauthn_credentials, [:credential_id])
    create index(:webauthn_credentials, [:user_id])

    create table(:backup_codes) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :code_hash, :string, null: false
      add :used_at, :utc_datetime

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:backup_codes, [:user_id])

    drop_if_exists unique_index(:users, [:email])
    drop_if_exists unique_index(:users, [:google_id])

    alter table(:users) do
      remove :email
      remove :google_id
      remove :name
      add :display_name, :string, default: "Owner"
      add :user_handle, :binary
    end
  end
end
