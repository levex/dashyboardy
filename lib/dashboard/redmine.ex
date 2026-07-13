defmodule Dashboard.Redmine do
  @moduledoc """
  Redmine issue storage and queries.
  """

  import Ecto.Query
  alias Dashboard.Repo
  alias Dashboard.Redmine.Issue
  alias Dashboard.Activities

  def upsert_issue(attrs) do
    result =
      %Issue{}
      |> Issue.changeset(attrs)
      |> Repo.insert(
        on_conflict:
          {:replace,
           [:title, :status, :assignee, :updated_at_source, :journal_summaries, :updated_at]},
        conflict_target: [:issue_id]
      )

    case result do
      {:ok, issue} ->
        base_url = Application.get_env(:dashboard, :redmine_url, "")

        Activities.upsert_activity(%{
          source: "redmine",
          source_instance: "issues",
          external_id: to_string(issue.issue_id),
          type: "issue_update",
          title: issue.title,
          summary: summarize_journals(issue.journal_summaries),
          author: issue.assignee,
          url: "#{base_url}/issues/#{issue.issue_id}",
          occurred_at: issue.updated_at_source,
          metadata: %{
            "status" => issue.status,
            "assignee" => issue.assignee
          }
        })

        {:ok, issue}

      error ->
        error
    end
  end

  defp summarize_journals(%{"entries" => entries}) when is_list(entries) do
    entries
    |> Enum.take(3)
    |> Enum.map_join(" · ", fn entry -> entry["notes"] || entry["detail"] || "" end)
  end

  defp summarize_journals(_), do: nil

  def list_recent(limit \\ 20) do
    Issue
    |> order_by([i], desc: i.updated_at_source)
    |> limit(^limit)
    |> Repo.all()
  end

  def list_assigned_to(me, limit \\ 20) do
    Issue
    |> where([i], i.assignee == ^me)
    |> order_by([i], desc: i.updated_at_source)
    |> limit(^limit)
    |> Repo.all()
  end

  def delete_older_than(days) do
    cutoff = DateTime.utc_now() |> DateTime.add(-days * 24 * 60 * 60, :second)

    {count, _} =
      from(i in Issue, where: i.updated_at_source < ^cutoff)
      |> Repo.delete_all()

    Activities.delete_older_than("redmine", days)
    count
  end
end
