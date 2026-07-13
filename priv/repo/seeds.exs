alias Dashboard.Rss

feeds = [
  %{
    name: "Old School RuneScape News",
    url: "https://secure.runescape.com/m=news/latest_news.rss?oldschool=true",
    enabled: true
  },
  %{
    name: "Hacker News",
    url: "https://hnrss.org/frontpage",
    enabled: true
  },
  %{
    name: "Lobsters",
    url: "https://lobste.rs/rss",
    enabled: true
  }
]

for feed <- feeds do
  case Rss.upsert_feed(feed) do
    {:ok, _} -> :ok
    {:error, changeset} -> raise "Failed to seed feed #{feed.name}: #{inspect(changeset.errors)}"
  end
end

IO.puts("Seeded #{length(feeds)} RSS feeds")
