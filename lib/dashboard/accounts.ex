defmodule Dashboard.Accounts do
  @moduledoc """
  Account helpers for the single dashboard owner.
  """

  alias Dashboard.Repo
  alias Dashboard.Accounts.User

  def get_user(id), do: Repo.get(User, id)
end
