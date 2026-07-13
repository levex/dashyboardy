defmodule Dashboard.Collectors.Redmine do
  @moduledoc """
  Polls Redmine for recently updated issues.
  """

  require Logger
  alias Dashboard.Redmine

  def name(_opts \\ []), do: "redmine"

  def collect(_opts \\ []) do
    base_url = Application.get_env(:dashboard, :redmine_url)
    api_key = Application.get_env(:dashboard, :redmine_api_key)

    if is_nil(base_url) or base_url == "" or is_nil(api_key) or api_key == "" do
      Logger.warning("Redmine collector skipped: missing REDMINE_URL or REDMINE_API_KEY")
      {:skipped, :not_configured}
    else
      fetch_recent_issues(base_url, api_key)
    end
  end

  defp fetch_recent_issues(base_url, api_key) do
    url = "#{String.trim_trailing(base_url, "/")}/issues.json?status_id=*&sort=updated_on:desc&limit=25"

    case req_get(url, api_key) do
      {:ok, %{"issues" => issues}} when is_list(issues) ->
        Enum.each(issues, &persist_issue(base_url, &1))
        {:ok, length(issues)}

      {:ok, body} ->
        Logger.warning("Redmine collector unexpected response: #{inspect(body)}")
        {:error, :unexpected_response}

      {:error, reason} ->
        Logger.warning("Redmine collector failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp persist_issue(_base_url, issue) do
    assignee = get_in(issue, ["assigned_to", "name"])
    status = get_in(issue, ["status", "name"])

    updated_at =
      case issue["updated_on"] do
        nil -> DateTime.utc_now(:second)
        iso -> parse_datetime(iso)
      end

    Redmine.upsert_issue(%{
      issue_id: issue["id"],
      title: issue["subject"] || "Untitled",
      status: status,
      assignee: assignee,
      updated_at_source: updated_at,
      journal_summaries: %{
        "entries" => [
          %{
            "detail" => "Status: #{status}",
            "notes" => issue["description"]
          }
        ]
      }
    })

    :ok
  end

  defp req_get(url, api_key) do
    headers = build_headers(api_key)

    case Req.get(url, headers: headers) do
      {:ok, %{status: 200, body: body}} -> {:ok, body}
      {:ok, %{status: status, body: body}} -> {:error, {status, body}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp build_headers(api_key) do
    base = [
      {"X-Redmine-API-Key", api_key},
      {"accept", "application/json"}
    ]

    case Application.get_env(:dashboard, :redmine_sso_bypass_header) do
      nil -> base
      {name, value} -> [{name, value} | base]
      header when is_binary(header) ->
        case String.split(header, ":", parts: 2) do
          [name, value] -> [{String.trim(name), String.trim(value)} | base]
          _ -> base
        end
    end
  end

  defp parse_datetime(iso) do
    case DateTime.from_iso8601(iso) do
      {:ok, dt, _} -> dt
      _ -> DateTime.utc_now(:second)
    end
  end
end
