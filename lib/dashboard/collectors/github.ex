defmodule Dashboard.Collectors.GitHub do
  @moduledoc """
  Polls GitHub repositories for recent commits.
  """

  require Logger
  alias Dashboard.Github

  @github_api "https://api.github.com"

  def name(opts \\ []) do
    case Keyword.get(opts, :repo) do
      nil -> "github"
      repo -> "github:#{repo}"
    end
  end

  def collect(opts \\ []) do
    repos =
      case Keyword.get(opts, :repo) do
        nil -> Github.repos()
        repo -> [repo]
      end

    token = github_token()

    results =
      Enum.map(repos, fn repo ->
        fetch_commits(repo, token)
      end)

    {:ok, results}
  end

  defp fetch_commits(repo, token) do
    url = "#{@github_api}/repos/#{repo}/commits?per_page=20"

    case req_get(url, token) do
      {:ok, commits} when is_list(commits) ->
        Enum.each(commits, &persist_commit(repo, &1))
        {:ok, repo, length(commits)}

      {:error, reason} ->
        Logger.warning("GitHub collector failed for #{repo}: #{inspect(reason)}")
        {:error, repo, reason}
    end
  end

  defp persist_commit(repo, %{"sha" => sha} = commit) do
    commit_data = commit["commit"] || %{}
    author = get_in(commit, ["commit", "author", "name"]) || get_in(commit, ["author", "login"])

    committed_at =
      case commit_data["author"]["date"] do
        nil -> DateTime.utc_now(:second)
        iso ->
          case DateTime.from_iso8601(iso) do
            {:ok, dt, _} -> dt
            _ -> DateTime.utc_now(:second)
          end
      end

    Github.upsert_commit(%{
      repo: repo,
      sha: sha,
      author: author,
      message: commit_data["message"] || "",
      committed_at: committed_at
    })
  end

  defp req_get(url, token) do
    headers = auth_headers(token)

    case Req.get(url, headers: headers) do
      {:ok, %{status: 200, body: body}} -> {:ok, body}
      {:ok, %{status: status, body: body}} -> {:error, {status, body}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp auth_headers(nil), do: [{"user-agent", "personal-dashboard"}]

  defp auth_headers(token) do
    [
      {"authorization", "Bearer #{token}"},
      {"user-agent", "personal-dashboard"},
      {"accept", "application/vnd.github+json"}
    ]
  end

  defp github_token do
    Application.get_env(:dashboard, :github_token) ||
      System.get_env("GITHUB_TOKEN") ||
      System.get_env("GITHUB_APP_TOKEN")
  end
end
