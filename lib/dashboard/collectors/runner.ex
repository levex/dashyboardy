defmodule Dashboard.Collectors.Runner do
  @moduledoc """
  Executes collectors with overlap protection.
  """

  alias Dashboard.Collectors.Lock

  def run(collector_module, opts \\ []) do
    name = collector_module.name(opts)

    Lock.with_lock(name, fn ->
      collector_module.collect(opts)
    end)
  end
end
