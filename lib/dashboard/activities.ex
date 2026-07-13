defmodule Dashboard.Activities do
  @moduledoc """
  Unified activity model and timeline queries.
  """

  import Ecto.Query
  alias Dashboard.Repo
  alias Dashboard.Activities.Activity

  def upsert_activity(attrs) do
    %Activity{}
    |> Activity.changeset(attrs)
    |> Repo.insert(
      on_conflict: {:replace, [:title, :summary, :author, :url, :occurred_at, :metadata, :updated_at]},
      conflict_target: [:source, :source_instance, :external_id]
    )
  end

  def list_activities(opts \\ []) do
    source = Keyword.get(opts, :source)
    limit = Keyword.get(opts, :limit, 50)

    Activity
    |> maybe_filter_source(source)
    |> order_by([a], desc: a.occurred_at)
    |> limit(^limit)
    |> Repo.all()
  end

  defp maybe_filter_source(query, nil), do: query
  defp maybe_filter_source(query, source), do: where(query, [a], a.source == ^source)

  def delete_older_than(source, days) do
    cutoff = DateTime.utc_now() |> DateTime.add(-days * 24 * 60 * 60, :second)

    from(a in Activity,
      where: a.source == ^source and a.occurred_at < ^cutoff
    )
    |> Repo.delete_all()
  end
end
