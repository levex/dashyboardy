defmodule DashboardWeb.AuthController do
  use DashboardWeb, :controller
  plug Ueberauth

  alias Dashboard.Accounts

  def request(conn, _params), do: conn

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    email = auth.info.email

    if Accounts.email_allowed?(email) do
      attrs = %{
        "email" => email,
        "name" => auth.info.name,
        "google_id" => to_string(auth.uid)
      }

      case Accounts.upsert_oauth_user(attrs) do
        {:ok, user} ->
          conn
          |> put_session(:user_id, user.id)
          |> redirect(to: "/")

        {:error, _changeset} ->
          conn
          |> put_flash(:error, "Could not sign in")
          |> redirect(to: "/")
      end
    else
      conn
      |> put_flash(:error, "Unauthorized account")
      |> redirect(to: "/")
    end
  end

  def callback(conn, _params) do
    conn
    |> put_flash(:error, "Authentication failed")
    |> redirect(to: "/")
  end

  def logout(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: "/")
  end

  def me(conn, _params) do
    user_id = get_session(conn, :user_id)

    case user_id && Accounts.get_user(user_id) do
      nil -> json(conn, %{authenticated: false})
      user -> json(conn, %{authenticated: true, user: %{id: user.id, email: user.email, name: user.name}})
    end
  end
end
