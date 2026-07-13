defmodule DashboardWeb.Router do
  use DashboardWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
  end

  pipeline :authenticated do
    plug DashboardWeb.Plugs.RequireAuth
  end

  scope "/api", DashboardWeb do
    pipe_through :api

    get "/auth/status", AuthController, :status
    get "/auth/me", AuthController, :me
    post "/auth/register/options", AuthController, :register_options
    post "/auth/register/verify", AuthController, :register_verify
    post "/auth/login/options", AuthController, :login_options
    post "/auth/login/verify", AuthController, :login_verify
    post "/auth/backup", AuthController, :backup_login
    post "/auth/logout", AuthController, :logout
  end

  scope "/api", DashboardWeb do
    pipe_through [:api, :authenticated]

    get "/layout", DashboardController, :layout
    put "/layout", DashboardController, :update_layout
    get "/github", DashboardController, :github
    get "/redmine", DashboardController, :redmine
    get "/rss", DashboardController, :rss
    post "/rss/:id/read", DashboardController, :mark_rss_read
    put "/rss/:id/saved", DashboardController, :mark_rss_saved
    get "/weather", DashboardController, :weather
    get "/timeline", DashboardController, :timeline
  end

  scope "/", DashboardWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:dashboard, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: DashboardWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  scope "/", DashboardWeb do
    pipe_through :browser

    get "/*path", PageController, :index
  end
end
