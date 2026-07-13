defmodule Dashboard.Github do
  @moduledoc """
  GitHub commit storage and queries.
  """

  import Ecto.Query
  alias Dashboard.Repo
  alias Dashboard.Github.Commit
  alias Dashboard.Activities

  @repos ["runelite/runelite", "runelite/plugin-hub", "Boilerplate-Inc/app"]

  def repos, do: @repos

  def fast_poll_repo, do: "Boilerplate-Inc/app"

  def upsert_commit(attrs) do
    result =
      %Commit{}
      |> Commit.changeset(attrs)
      |> Repo.insert(
        on_conflict: {:replace, [:author, :message, :committed_at]},
        conflict_target: [:repo, :sha]
      )

  case result do
      {:ok, commit} ->
        Activities.upsert_activity(%{
          source: "github",
          source_instance: commit.repo,
          external_id: commit.sha,
          type: "commit",
          title: String.slice(commit.message, 0, 120),
          summary: commit.message,
          author: commit.author,
          url: "https://github.com/#{commit.repo}/commit/#{commit.sha}",
          occurred_at: commit.committed_at,
          metadata: %{"sha" => commit.sha}
        })

        {:ok, commit}

      error ->
        error
    end
  end

  def list_commits(opts \\ []) do
    repo = Keyword.get(opts, :repo)
    limit = Keyword.get(opts, :limit, 20)

    Commit
    |> maybe_filter_repo(repo)
    |> order_by([c], desc: c.committed_at)
    |> limit(^limit)
    |> Repo.all()
  end

  defp maybe_filter_repo(query, nil), do: query
  defp maybe_filter_repo(query, repo), do: where(query, [c], c.repo == ^repo)

  def delete_older_than(days) do
    cutoff = DateTime.utc_now() |> DateTime.add(-days * 24 * 60 * 60, :second)

    {count, _} =
      from(c in Commit, where: c.committed_at < ^cutoff)
      |> Repo.delete_all()

    Activities.delete_older_than("github", days)
    count
  end
end
