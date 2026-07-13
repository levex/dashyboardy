defmodule DashboardWeb.WebAuthnJSON do
  @moduledoc false

  @pub_key_cred_params [
    %{type: "public-key", alg: -7},
    %{type: "public-key", alg: -257}
  ]

  def registration_options(challenge, user_handle, display_name) do
    %{
      publicKey: %{
        challenge: base64url_encode(challenge.bytes),
        rp: %{name: "Personal Dashboard", id: challenge.rp_id},
        user: %{
          id: base64url_encode(user_handle),
          name: display_name,
          displayName: display_name
        },
        pubKeyCredParams: @pub_key_cred_params,
        timeout: 60_000,
        attestation: "none",
        authenticatorSelection: %{
          residentKey: "required",
          userVerification: "preferred"
        }
      }
    }
  end

  def authentication_options(challenge, credential_ids) do
    allow_credentials =
      Enum.map(credential_ids, fn credential_id ->
        %{type: "public-key", id: credential_id}
      end)

    base = %{
      challenge: base64url_encode(challenge.bytes),
      rpId: challenge.rp_id,
      timeout: 60_000,
      userVerification: "preferred"
    }

    public_key =
      if allow_credentials == [] do
        base
      else
        Map.put(base, :allowCredentials, allow_credentials)
      end

    %{publicKey: public_key}
  end

  defp base64url_encode(binary) when is_binary(binary) do
    Base.url_encode64(binary, padding: false)
  end
end
