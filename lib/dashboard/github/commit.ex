defmodule Dashboard.Github.Commit do
  use Ecto.Schema
  import Ecto.Changeset

  schema "github_commits" do
    field :repo, :string
    field :sha, :string
    field :author, :string
    field :message, :string
    field :committed_at, :utc_datetime

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(commit, attrs) do
    commit
    |> cast(attrs, [:repo, :sha, :author, :message, :committed_at])
    |> validate_required([:repo, :sha, :message, :committed_at])
    |> unique_constraint([:repo, :sha])
  end
end
