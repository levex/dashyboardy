defmodule Dashboard.Auth.CoseKeyCodec do
  @moduledoc false

  @doc """
  Wax stores credential public keys as COSE key maps (integer keys).
  Serialize for SQLite storage and decode for Wax.authenticate/5.
  """
  def encode(cose_key) when is_map(cose_key) do
    :erlang.term_to_binary(cose_key)
  end

  def decode(binary) when is_binary(binary) do
    :erlang.binary_to_term(binary, [:safe])
  end
end
