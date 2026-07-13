defmodule Dashboard.Collectors.Cleanup do
  @moduledoc """
  Nightly retention cleanup. Saved RSS items are never deleted.
  """

  require Logger
  alias Dashboard.{Github, Redmine, Rss, Weather}

  @retention %{
    github: 90,
    rss: 30,
    weather: 7,
    redmine: 180
  }

  def name(_opts \\ []), do: "cleanup"

  def collect(_opts \\ []) do
    github_count = Github.delete_older_than(@retention.github)
    redmine_count = Redmine.delete_older_than(@retention.redmine)
    {rss_count, _} = Rss.delete_old_entries(@retention.rss)
    {weather_count, _} = Weather.delete_older_than(@retention.weather)

    Logger.info(
      "Retention cleanup complete: github=#{github_count}, redmine=#{redmine_count}, rss=#{rss_count}, weather=#{weather_count}"
    )

    execute_vacuum()

    {:ok,
     %{
       github: github_count,
       redmine: redmine_count,
       rss: rss_count,
       weather: weather_count
     }}
  end

  defp execute_vacuum do
    Ecto.Adapters.SQL.query(Dashboard.Repo, "PRAGMA incremental_vacuum", [])
  rescue
    error -> Logger.warning("incremental_vacuum failed: #{inspect(error)}")
  end
end
