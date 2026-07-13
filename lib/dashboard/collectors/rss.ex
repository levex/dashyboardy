defmodule Dashboard.Collectors.RSS do
  @moduledoc """
  Polls configured RSS/Atom feeds.
  """

  require Logger
  alias Dashboard.Rss

  def name(_opts \\ []), do: "rss"

  def collect(_opts \\ []) do
    feeds = Rss.list_enabled_feeds()

    results =
      Enum.map(feeds, fn feed ->
        fetch_feed(feed)
      end)

    {:ok, results}
  end

  defp fetch_feed(feed) do
    case Req.get(feed.url, headers: [{"user-agent", "personal-dashboard"}]) do
      {:ok, %{status: 200, body: body}} ->
        parse_and_store(feed, body)
        {:ok, feed.name}

      {:ok, %{status: status}} ->
        Logger.warning("RSS collector failed for #{feed.name}: HTTP #{status}")
        {:error, feed.name, status}

      {:error, reason} ->
        Logger.warning("RSS collector failed for #{feed.name}: #{inspect(reason)}")
        {:error, feed.name, reason}
    end
  end

  defp parse_and_store(feed, body) do
    entries =
      case FastRSS.parse_rss(body) do
        {:ok, %{"items" => items}} when is_list(items) ->
          Enum.map(items, &normalize_rss_item/1)

        _ ->
          case FastRSS.parse_atom(body) do
            {:ok, %{"entries" => entries}} when is_list(entries) ->
              Enum.map(entries, &normalize_atom_entry/1)

            _ ->
              Logger.warning("RSS parse error for #{feed.name}")
              []
          end
      end

    Enum.each(entries, fn entry ->
      Rss.upsert_entry(%{
        feed_id: feed.id,
        external_id: entry.id,
        title: entry.title,
        url: entry.url,
        published_at: entry.published_at,
        summary: entry.summary
      })
    end)
  end

  defp normalize_rss_item(item) do
    %{
      id: item["guid"] || item["link"] || item["title"] || Ecto.UUID.generate(),
      title: item["title"] || "Untitled",
      url: item["link"] || "",
      published_at: parse_date(item["pub_date"]),
      summary: item["description"] || item["content"]
    }
  end

  defp normalize_atom_entry(entry) do
    link =
      case entry["links"] do
        [%{"href" => href} | _] -> href
        _ -> entry["id"] || ""
      end

    %{
      id: entry["id"] || link || entry["title"] || Ecto.UUID.generate(),
      title: entry["title"] || "Untitled",
      url: link,
      published_at: parse_date(entry["published"] || entry["updated"]),
      summary: entry["summary"] || entry["content"]
    }
  end

  defp parse_date(nil), do: DateTime.utc_now(:second)

  defp parse_date(date) when is_binary(date) do
    case DateTime.from_iso8601(date) do
      {:ok, dt, _} -> dt
      _ -> DateTime.utc_now(:second)
    end
  end

  defp parse_date(_), do: DateTime.utc_now(:second)
end
