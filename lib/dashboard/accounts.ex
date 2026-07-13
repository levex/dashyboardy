defmodule Dashboard.Accounts do
  @moduledoc """
  Account management for the single authorized Google OAuth user.
  """

  alias Dashboard.Repo
  alias Dashboard.Accounts.User

  def get_user(id), do: Repo.get(User, id)

  def get_user_by_google_id(google_id) do
    Repo.get_by(User, google_id: google_id)
  end

  def get_user_by_email(email) do
    Repo.get_by(User, email: email)
  end

  def upsert_oauth_user(attrs) do
    case get_user_by_google_id(attrs["google_id"]) do
      nil ->
        %User{}
        |> User.changeset(attrs)
        |> Repo.insert()

      user ->
        user
        |> User.changeset(attrs)
        |> Repo.update()
    end
  end

  def email_allowed?(email) do
    case Application.get_env(:dashboard, :allowed_email) do
      nil -> true
      allowed -> String.downcase(email) == String.downcase(allowed)
    end
  end
end
