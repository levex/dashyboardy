defmodule Dashboard.Auth do
  @moduledoc """
  Passkey (WebAuthn) credentials and backup-code recovery.
  """

  import Ecto.Query
  alias Dashboard.Repo
  alias Dashboard.Accounts.User
  alias Dashboard.Auth.{Credential, BackupCode}

  def enrolled? do
    Repo.exists?(from c in Credential, select: 1, limit: 1)
  end

  def get_user(id), do: Repo.get(User, id)

  def list_credentials do
    Repo.all(Credential)
  end

  def credential_pairs do
    for cred <- list_credentials() do
      {cred.credential_id, cred.public_key}
    end
  end

  def get_credential_by_id(credential_id) do
    Repo.get_by(Credential, credential_id: credential_id)
  end

  def create_owner!(user_handle, credential_id, public_key, sign_count, label \\ nil) do
    Repo.transaction(fn ->
      {:ok, user} =
        %User{}
        |> User.changeset(%{display_name: "Owner", user_handle: user_handle})
        |> Repo.insert()

      {:ok, credential} =
        %Credential{}
        |> Credential.changeset(%{
          user_id: user.id,
          credential_id: credential_id,
          public_key: public_key,
          sign_count: sign_count,
          label: label
        })
        |> Repo.insert()

      backup_codes = generate_backup_codes!(user.id)

      {user, credential, backup_codes}
    end)
    |> case do
      {:ok, result} -> result
      {:error, reason} -> raise "Failed to create owner: #{inspect(reason)}"
    end
  end

  def add_credential!(user_id, credential_id, public_key, sign_count, label \\ nil) do
    %Credential{}
    |> Credential.changeset(%{
      user_id: user_id,
      credential_id: credential_id,
      public_key: public_key,
      sign_count: sign_count,
      label: label
    })
    |> Repo.insert!()
  end

  def update_sign_count!(%Credential{} = credential, sign_count) do
    credential
    |> Credential.changeset(%{sign_count: sign_count})
    |> Repo.update!()
  end

  def generate_backup_codes!(user_id, count \\ 10) do
    codes =
      for _ <- 1..count do
        part1 = :crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)
        part2 = :crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)
        "#{part1}-#{part2}"
      end

    Enum.each(codes, fn code ->
      %BackupCode{}
      |> BackupCode.changeset(%{
        user_id: user_id,
        code_hash: Bcrypt.hash_pwd_salt(code)
      })
      |> Repo.insert!()
    end)

    codes
  end

  def verify_backup_code(code) when is_binary(code) do
    normalized = String.trim(code)

    from(b in BackupCode,
      where: is_nil(b.used_at),
      preload: [:user]
    )
    |> Repo.all()
    |> Enum.find_value(fn backup_code ->
      if Bcrypt.verify_pass(normalized, backup_code.code_hash) do
        backup_code
      end
    end)
    |> case do
      nil ->
        {:error, :invalid}

      backup_code ->
        backup_code
        |> BackupCode.changeset(%{used_at: DateTime.utc_now(:second)})
        |> Repo.update!()

        {:ok, backup_code.user}
    end
  end

  def unused_backup_code_count(user_id) do
    from(b in BackupCode, where: b.user_id == ^user_id and is_nil(b.used_at), select: count(b.id))
    |> Repo.one()
  end
end
