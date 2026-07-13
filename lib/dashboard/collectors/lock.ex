defmodule Dashboard.Collectors.Lock do
  @moduledoc """
  Prevents collector jobs from overlapping.
  """

  use GenServer
  require Logger

  @table :collector_locks

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    :ets.new(@table, [:named_table, :set, :protected])
    {:ok, state}
  end

  def with_lock(name, fun) when is_function(fun, 0) do
    case try_acquire(name) do
      :ok ->
        try do
          fun.()
        after
          release(name)
        end

      :busy ->
        Logger.info("Collector #{name} skipped: already running")
        {:skipped, :busy}
    end
  end

  def try_acquire(name) do
    GenServer.call(__MODULE__, {:try_acquire, name})
  end

  def release(name) do
    GenServer.call(__MODULE__, {:release, name})
  end

  @impl true
  def handle_call({:try_acquire, name}, _from, state) do
    case :ets.lookup(@table, name) do
      [{^name, true}] ->
        {:reply, :busy, state}

      [] ->
        :ets.insert(@table, {name, true})
        {:reply, :ok, state}
    end
  end

  @impl true
  def handle_call({:release, name}, _from, state) do
    :ets.delete(@table, name)
    {:reply, :ok, state}
  end
end
