defmodule DashboardWeb.DashboardController do
  use DashboardWeb, :controller

  alias Dashboard.{Activities, Github, Redmine, Rss, Weather, Widgets}

  def layout(conn, _params) do
    user_id = conn.assigns.current_user_id
    json(conn, %{layout: Widgets.get_layout(user_id)})
  end

  def update_layout(conn, %{"layout" => layout}) do
    user_id = conn.assigns.current_user_id

    case Widgets.save_layout(user_id, layout) do
      {:ok, _} -> json(conn, %{ok: true})
      {:error, _} -> conn |> put_status(:unprocessable_entity) |> json(%{error: "invalid layout"})
    end
  end

  def github(conn, params) do
    repo =
      case params["repo"] do
        r when r in [nil, "", "all"] -> nil
        r -> r
      end

    json(conn, %{
      repos: Github.repos(),
      commits: serialize_commits(Github.list_commits(repo: repo, limit: 30))
    })
  end

  def redmine(conn, params) do
    me = Application.get_env(:dashboard, :redmine_assignee_name)

    issues =
      case params["assigned"] do
        "true" when not is_nil(me) -> Redmine.list_assigned_to(me)
        _ -> Redmine.list_recent(30)
      end

    json(conn, %{issues: serialize_issues(issues)})
  end

  def rss(conn, params) do
    opts =
      []
      |> maybe_add(:feed_id, params["feed_id"])
      |> maybe_add(:unread_only, params["unread"] == "true")
      |> maybe_add(:saved_only, params["saved"] == "true")
      |> Keyword.put(:limit, 40)

    json(conn, %{
      feeds: Enum.map(Rss.list_feeds(), &%{id: &1.id, name: &1.name, url: &1.url, enabled: &1.enabled}),
      entries: serialize_entries(Rss.list_entries(opts))
    })
  end

  def mark_rss_read(conn, %{"id" => id}) do
    case Rss.mark_read(id, true) do
      {:ok, _} -> json(conn, %{ok: true})
      {:error, :not_found} -> conn |> put_status(:not_found) |> json(%{error: "not found"})
      {:error, _} -> conn |> put_status(:unprocessable_entity) |> json(%{error: "failed"})
    end
  end

  def mark_rss_saved(conn, %{"id" => id, "saved" => saved}) do
    case Rss.mark_saved(id, saved in [true, "true"]) do
      {:ok, _} -> json(conn, %{ok: true})
      {:error, :not_found} -> conn |> put_status(:not_found) |> json(%{error: "not found"})
      {:error, _} -> conn |> put_status(:unprocessable_entity) |> json(%{error: "failed"})
    end
  end

  def weather(conn, _params) do
    readings =
      Weather.latest_by_city()
      |> Enum.map(fn {city, reading} ->
        %{
          city: city,
          temperature: reading && reading.temperature,
          conditions: reading && reading.conditions,
          humidity: reading && reading.humidity,
          recorded_at: reading && reading.recorded_at
        }
      end)

    json(conn, %{readings: readings})
  end

  def timeline(conn, params) do
    source = params["source"]
    activities = Activities.list_activities(source: source, limit: 60)
    json(conn, %{activities: serialize_activities(activities)})
  end

  def pull(conn, _params) do
    json(conn, Dashboard.Collectors.pull_all())
  end

  defp maybe_add(opts, _key, nil), do: opts
  defp maybe_add(opts, _key, ""), do: opts
  defp maybe_add(opts, key, value), do: Keyword.put(opts, key, value)

  defp serialize_commits(commits) do
    Enum.map(commits, fn c ->
      %{
        id: c.id,
        repo: c.repo,
        sha: String.slice(c.sha, 0, 7),
        author: c.author,
        message: c.message,
        committed_at: c.committed_at
      }
    end)
  end

  defp serialize_issues(issues) do
    Enum.map(issues, fn i ->
      %{
        id: i.id,
        issue_id: i.issue_id,
        title: i.title,
        status: i.status,
        assignee: i.assignee,
        updated_at: i.updated_at_source
      }
    end)
  end

  defp serialize_entries(entries) do
    Enum.map(entries, fn e ->
      %{
        id: e.id,
        feed_id: e.feed_id,
        title: e.title,
        url: e.url,
        summary: e.summary,
        published_at: e.published_at,
        read: e.read,
        saved: e.saved
      }
    end)
  end

  defp serialize_activities(activities) do
    Enum.map(activities, fn a ->
      %{
        id: a.id,
        source: a.source,
        source_instance: a.source_instance,
        type: a.type,
        title: a.title,
        summary: a.summary,
        author: a.author,
        url: a.url,
        occurred_at: a.occurred_at
      }
    end)
  end
end
