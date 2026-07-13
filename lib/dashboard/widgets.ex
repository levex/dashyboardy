defmodule Dashboard.Widgets do
  @moduledoc """
  Dashboard widget layout persistence.
  """

  alias Dashboard.Repo
  alias Dashboard.Widgets.Layout

  @default_layout %{
    "widgets" => [
      %{"id" => "clock", "x" => 0, "y" => 0, "w" => 3, "h" => 2, "collapsed" => false},
      %{"id" => "weather", "x" => 3, "y" => 0, "w" => 3, "h" => 2, "collapsed" => false},
      %{
        "id" => "github",
        "x" => 6,
        "y" => 0,
        "w" => 6,
        "h" => 6,
        "collapsed" => false,
        "settings" => %{"repo" => "all"}
      },
      %{"id" => "redmine", "x" => 0, "y" => 2, "w" => 3, "h" => 5, "collapsed" => false},
      %{"id" => "rss", "x" => 3, "y" => 2, "w" => 3, "h" => 5, "collapsed" => false},
      %{"id" => "timeline", "x" => 0, "y" => 7, "w" => 12, "h" => 5, "collapsed" => false}
    ],
    "columns" => 12
  }

  def default_layout, do: @default_layout

  def get_layout(user_id) do
    case Repo.get_by(Layout, user_id: user_id) do
      nil -> @default_layout
      %Layout{layout: layout} -> layout
    end
  end

  def save_layout(user_id, layout) do
    case Repo.get_by(Layout, user_id: user_id) do
      nil ->
        %Layout{}
        |> Layout.changeset(%{user_id: user_id, layout: layout})
        |> Repo.insert()

      existing ->
        existing
        |> Layout.changeset(%{layout: layout})
        |> Repo.update()
    end
  end
end
