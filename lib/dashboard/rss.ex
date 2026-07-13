defmodule Dashboard.Rss do
  @moduledoc """
  RSS feed configuration and entry management.
  """

  import Ecto.Query
  alias Dashboard.Repo
  alias Dashboard.Rss.{Feed, Entry}
  alias Dashboard.Activities

  def list_feeds do
    Repo.all(Feed)
  end

  def list_enabled_feeds do
    Feed |> where([f], f.enabled == true) |> Repo.all()
  end

  def upsert_feed(attrs) do
    %Feed{}
    |> Feed.changeset(attrs)
    |> Repo.insert(
      on_conflict: {:replace, [:name, :enabled, :updated_at]},
      conflict_target: [:url]
    )
  end

  def upsert_entry(attrs) do
    feed = Repo.get!(Feed, attrs.feed_id)

    result =
      %Entry{}
      |> Entry.changeset(attrs)
      |> Repo.insert(
        on_conflict: {:replace, [:title, :url, :published_at, :summary, :updated_at]},
        conflict_target: [:feed_id, :external_id]
      )

    case result do
      {:ok, entry} ->
        Activities.upsert_activity(%{
          source: "rss",
          source_instance: feed.name,
          external_id: entry.external_id,
          type: "rss_entry",
          title: entry.title,
          summary: entry.summary,
          author: nil,
          url: entry.url,
          occurred_at: entry.published_at || DateTime.utc_now(:second),
          metadata: %{"feed_id" => feed.id}
        })

        {:ok, entry}

      error ->
        error
    end
  end

  def list_entries(opts \\ []) do
    feed_id = Keyword.get(opts, :feed_id)
    unread_only = Keyword.get(opts, :unread_only, false)
    saved_only = Keyword.get(opts, :saved_only, false)
    limit = Keyword.get(opts, :limit, 30)

    Entry
    |> maybe_filter_feed(feed_id)
    |> maybe_filter_unread(unread_only)
    |> maybe_filter_saved(saved_only)
    |> order_by([e], desc: e.published_at)
    |> limit(^limit)
    |> Repo.all()
  end

  defp maybe_filter_feed(query, nil), do: query
  defp maybe_filter_feed(query, feed_id), do: where(query, [e], e.feed_id == ^feed_id)

  defp maybe_filter_unread(query, false), do: query
  defp maybe_filter_unread(query, true), do: where(query, [e], e.read == false)

  defp maybe_filter_saved(query, false), do: query
  defp maybe_filter_saved(query, true), do: where(query, [e], e.saved == true)

  def mark_read(id, read \\ true) do
    Entry
    |> Repo.get(id)
    |> case do
      nil -> {:error, :not_found}
      entry -> entry |> Entry.changeset(%{read: read}) |> Repo.update()
    end
  end

  def mark_saved(id, saved \\ true) do
    Entry
    |> Repo.get(id)
    |> case do
      nil -> {:error, :not_found}
      entry -> entry |> Entry.changeset(%{saved: saved}) |> Repo.update()
    end
  end

  def delete_old_entries(days) do
    cutoff = DateTime.utc_now() |> DateTime.add(-days * 24 * 60 * 60, :second)

    from(e in Entry,
      where: e.published_at < ^cutoff and e.saved == false
    )
    |> Repo.delete_all()
  end
end
