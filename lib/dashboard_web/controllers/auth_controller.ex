defmodule DashboardWeb.AuthController do
  use DashboardWeb, :controller

  require Logger

  alias Dashboard.{Accounts, Auth}
  alias DashboardWeb.WebAuthnJSON

  def status(conn, _params) do
    user_id = get_session(conn, :user_id)

    json(conn, %{
      enrolled: Auth.enrolled?(),
      authenticated: not is_nil(user_id),
      user: user_payload(user_id)
    })
  end

  def me(conn, _params) do
    user_id = get_session(conn, :user_id)

    case user_id && Accounts.get_user(user_id) do
      nil -> json(conn, %{authenticated: false, enrolled: Auth.enrolled?()})
      user -> json(conn, %{authenticated: true, enrolled: true, user: serialize_user(user)})
    end
  end

  def register_options(conn, _params) do
    if Auth.enrolled?() do
      conn |> put_status(:forbidden) |> json(%{error: "already_enrolled"})
    else
      user_handle = :crypto.strong_rand_bytes(32)

      challenge =
        Wax.new_registration_challenge(
          authenticator_selection: %{
            resident_key: :required,
            user_verification: :preferred
          }
        )

      conn
      |> put_session(:registration_challenge, challenge)
      |> put_session(:registration_user_handle, user_handle)
      |> json(WebAuthnJSON.registration_options(challenge, user_handle, "Owner"))
    end
  end

  def register_verify(conn, %{"credential" => credential}) do
    challenge = get_session(conn, :registration_challenge)
    user_handle = get_session(conn, :registration_user_handle)

    with true <- not Auth.enrolled?(),
         %Wax.Challenge{} <- challenge,
         user_handle when is_binary(user_handle) <- user_handle,
         {:ok, attestation_object, client_data_json} <- decode_registration(credential),
         {:ok, {authenticator_data, _result}} <-
           Wax.register(attestation_object, client_data_json, challenge) do
      credential_id = credential["id"]
      sign_count = authenticator_data.sign_count

      cose_key =
        authenticator_data.attested_credential_data.credential_public_key

      {user, _credential, backup_codes} =
        Auth.create_owner!(user_handle, credential_id, cose_key, sign_count)

      conn
      |> delete_session(:registration_challenge)
      |> delete_session(:registration_user_handle)
      |> put_session(:user_id, user.id)
      |> json(%{
        ok: true,
        user: serialize_user(user),
        backup_codes: backup_codes
      })
    else
      false ->
        conn |> put_status(:forbidden) |> json(%{error: "already_enrolled"})

      nil ->
        conn |> put_status(:bad_request) |> json(%{error: "missing_challenge"})

      {:error, reason} ->
        Logger.warning("Passkey registration failed: #{inspect(reason)}")
        conn |> put_status(:unprocessable_entity) |> json(%{error: "registration_failed"})
    end
  end

  def login_options(conn, _params) do
    if Auth.enrolled?() do
      credentials = Auth.list_credentials()
      pairs = Auth.credential_pairs()

      challenge =
        case pairs do
          [] -> Wax.new_authentication_challenge()
          pairs -> Wax.new_authentication_challenge(allow_credentials: pairs)
        end

      credential_ids = Enum.map(credentials, & &1.credential_id)

      conn
      |> put_session(:authentication_challenge, challenge)
      |> json(WebAuthnJSON.authentication_options(challenge, credential_ids))
    else
      conn |> put_status(:not_found) |> json(%{error: "not_enrolled"})
    end
  end

  def login_verify(conn, %{"credential" => credential}) do
    challenge = get_session(conn, :authentication_challenge)

    unless match?(%Wax.Challenge{}, challenge) do
      conn |> put_status(:bad_request) |> json(%{error: "missing_challenge"})
    else
      with {:ok, credential_id, authenticator_data_raw, sig_raw, client_data_json} <-
             decode_authentication(credential),
           {:ok, auth_data} <-
             Wax.authenticate(
               credential_id,
               authenticator_data_raw,
               sig_raw,
               client_data_json,
               challenge,
               Auth.credential_pairs()
             ),
           %Dashboard.Auth.Credential{} = stored <- Auth.get_credential_by_id(credential_id),
           true <- auth_data.sign_count >= stored.sign_count do
        Auth.update_sign_count!(stored, auth_data.sign_count)

        conn
        |> delete_session(:authentication_challenge)
        |> put_session(:user_id, stored.user_id)
        |> json(%{ok: true, user: serialize_user(Accounts.get_user(stored.user_id))})
      else
        false ->
          conn |> put_status(:unprocessable_entity) |> json(%{error: "invalid_sign_count"})

        nil ->
          conn |> put_status(:unprocessable_entity) |> json(%{error: "unknown_credential"})

        {:error, reason} ->
          Logger.warning("Passkey login failed: #{inspect(reason)}")
          conn |> put_status(:unprocessable_entity) |> json(%{error: "authentication_failed"})
      end
    end
  end

  def backup_login(conn, %{"code" => code}) do
    case Auth.verify_backup_code(code) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> json(%{ok: true, user: serialize_user(user)})

      {:error, :invalid} ->
        conn |> put_status(:unauthorized) |> json(%{error: "invalid_code"})
    end
  end

  def logout(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> json(%{ok: true})
  end

  defp decode_registration(%{"attestationObject" => att_obj, "clientDataJSON" => client_data}) do
    with {:ok, attestation_object} <- decode_base64url(att_obj),
         {:ok, client_data_json} <- decode_client_data(client_data) do
      {:ok, attestation_object, client_data_json}
    end
  end

  defp decode_registration(_), do: {:error, :invalid_payload}

  defp decode_authentication(%{
         "id" => credential_id,
         "authenticatorData" => auth_data,
         "clientDataJSON" => client_data_json,
         "signature" => signature
       }) do
    with {:ok, authenticator_data_raw} <- decode_base64url(auth_data),
         {:ok, sig_raw} <- decode_base64url(signature),
         {:ok, client_data} <- decode_client_data(client_data_json) do
      {:ok, credential_id, authenticator_data_raw, sig_raw, client_data}
    end
  end

  defp decode_authentication(_), do: {:error, :invalid_payload}

  defp decode_base64url(value) when is_binary(value) do
    case Base.url_decode64(value, padding: false) do
      {:ok, binary} -> {:ok, binary}
      :error -> Base.decode64(value)
    end
  end

  defp decode_client_data(value) when is_binary(value) do
    case decode_base64url(value) do
      {:ok, binary} -> {:ok, binary}
      error -> error
    end
  end

  defp user_payload(nil), do: nil

  defp user_payload(user_id) do
    case Accounts.get_user(user_id) do
      nil -> nil
      user -> serialize_user(user)
    end
  end

  defp serialize_user(user) do
    %{
      id: user.id,
      display_name: user.display_name,
      backup_codes_remaining: Auth.unused_backup_code_count(user.id)
    }
  end
end
