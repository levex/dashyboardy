defmodule Dashboard.Collectors do
  @moduledoc """
  Manual and scheduled data collection orchestration.
  """

  alias Dashboard.Collectors.{Runner, GitHub, Redmine, RSS, Weather}

  @manual_collectors [
    {:github, GitHub, []},
    {:redmine, Redmine, []},
    {:rss, RSS, []},
    {:weather, Weather, []}
  ]

  def pull_all do
    results =
      Enum.map(@manual_collectors, fn {source, module, opts} ->
        pull_one(source, module, opts)
      end)

    %{
      pulled_at: DateTime.utc_now(:second),
      results: results
    }
  end

  defp pull_one(source, module, opts) do
    case Runner.run(module, opts) do
      {:skipped, :busy} ->
        %{source: source, status: "skipped", message: "Already running"}

      {:skipped, :not_configured} ->
        %{source: source, status: "skipped", message: "Not configured"}

      {:ok, data} ->
        summarize_ok(source, data)

      {:error, reason} ->
        %{
          source: source,
          status: "error",
          message: format_error(reason),
          failures: []
        }
    end
  end

  defp summarize_ok(:github, results) when is_list(results) do
    summarize_list_results(:github, results, fn
      {:ok, repo, count} -> {:ok, repo, "#{count} commits"}
      {:error, repo, reason} -> {:error, repo, format_error(reason)}
    end)
  end

  defp summarize_ok(:rss, results) when is_list(results) do
    summarize_list_results(:rss, results, fn
      {:ok, name} -> {:ok, name, "updated"}
      {:error, name, reason} -> {:error, name, format_error(reason)}
    end)
  end

  defp summarize_ok(:weather, results) when is_list(results) do
    summarize_list_results(:weather, results, fn
      {:ok, city} -> {:ok, city, "updated"}
      {:error, city, reason} -> {:error, city, format_error(reason)}
    end)
  end

  defp summarize_ok(:redmine, count) when is_integer(count) do
    %{
      source: :redmine,
      status: "ok",
      message: "#{count} issues updated",
      failures: []
    }
  end

  defp summarize_ok(source, _data) do
    %{source: source, status: "ok", message: "Completed", failures: []}
  end

  defp summarize_list_results(source, results, mapper) do
    mapped = Enum.map(results, mapper)

    failures =
      Enum.flat_map(mapped, fn
        {:error, name, message} -> [%{name: to_string(name), error: message}]
        _ -> []
      end)

    oks = Enum.count(mapped, &match?({:ok, _, _}, &1))
    total = length(mapped)

    status =
      cond do
        failures == [] -> "ok"
        oks == 0 -> "error"
        true -> "partial"
      end

    message =
      case {oks, total, failures} do
        {0, 0, _} -> "Nothing to fetch"
        {n, n, _} when n > 0 -> "All #{n} updated"
        {oks, total, _} -> "#{oks}/#{total} succeeded"
      end

    %{
      source: source,
      status: status,
      message: message,
      failures: failures
    }
  end

  defp format_error({status, _body}) when is_integer(status), do: "HTTP #{status}"
  defp format_error(:unexpected_response), do: "Unexpected API response"
  defp format_error(:not_configured), do: "Not configured"
  defp format_error(reason) when is_binary(reason), do: reason
  defp format_error(reason), do: inspect(reason, limit: 120)
end
