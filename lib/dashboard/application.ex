defmodule Dashboard.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DashboardWeb.Telemetry,
      Dashboard.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:dashboard, :ecto_repos), skip: skip_migrations?()},
      {Task, fn -> Dashboard.Repo.configure_sqlite!() end},
      {DNSCluster, query: Application.get_env(:dashboard, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Dashboard.PubSub},
      Dashboard.Collectors.Lock,
      Dashboard.Scheduler,
      DashboardWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Dashboard.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DashboardWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") == nil
  end
end
