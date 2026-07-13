defmodule Dashboard.Repo do
  use Ecto.Repo,
    otp_app: :dashboard,
    adapter: Ecto.Adapters.SQLite3

  def configure_sqlite! do
    Ecto.Adapters.SQL.query!(__MODULE__, "PRAGMA journal_mode = WAL", [])
    Ecto.Adapters.SQL.query!(__MODULE__, "PRAGMA foreign_keys = ON", [])
    Ecto.Adapters.SQL.query!(__MODULE__, "PRAGMA auto_vacuum = INCREMENTAL", [])
    :ok
  end
end
