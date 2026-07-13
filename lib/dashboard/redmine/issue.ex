defmodule Dashboard.Redmine.Issue do
  use Ecto.Schema
  import Ecto.Changeset

  schema "redmine_issues" do
    field :issue_id, :integer
    field :title, :string
    field :status, :string
    field :assignee, :string
    field :updated_at_source, :utc_datetime
    field :journal_summaries, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  def changeset(issue, attrs) do
    issue
    |> cast(attrs, [:issue_id, :title, :status, :assignee, :updated_at_source, :journal_summaries])
    |> validate_required([:issue_id, :title, :updated_at_source])
    |> unique_constraint(:issue_id)
  end
end
