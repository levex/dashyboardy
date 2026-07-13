# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :dashboard,
  ecto_repos: [Dashboard.Repo],
  generators: [timestamp_type: :utc_datetime],
  allowed_email: System.get_env("ALLOWED_EMAIL"),
  github_token: System.get_env("GITHUB_TOKEN"),
  redmine_url: System.get_env("REDMINE_URL"),
  redmine_api_key: System.get_env("REDMINE_API_KEY"),
  redmine_sso_bypass_header: System.get_env("REDMINE_SSO_BYPASS_HEADER"),
  redmine_assignee_name: System.get_env("REDMINE_ASSIGNEE_NAME")

config :ueberauth, Ueberauth,
  providers: [
    google: {Ueberauth.Strategy.Google, [default_scope: "email profile"]}
  ]

config :ueberauth, Ueberauth.Strategy.Google.OAuth,
  client_id: System.get_env("GOOGLE_CLIENT_ID"),
  client_secret: System.get_env("GOOGLE_CLIENT_SECRET")

config :dashboard, Dashboard.Scheduler,
  jobs: [
    {"*/5 * * * *", {Dashboard.Collectors.Runner, :run, [Dashboard.Collectors.GitHub]}},
    {"*/2 * * * *",
     {Dashboard.Collectors.Runner, :run, [Dashboard.Collectors.GitHub, [repo: "Boilerplate-Inc/app"]]}},
    {"*/5 * * * *", {Dashboard.Collectors.Runner, :run, [Dashboard.Collectors.Redmine]}},
    {"*/10 * * * *", {Dashboard.Collectors.Runner, :run, [Dashboard.Collectors.RSS]}},
    {"*/20 * * * *", {Dashboard.Collectors.Runner, :run, [Dashboard.Collectors.Weather]}},
    {"0 3 * * *", {Dashboard.Collectors.Runner, :run, [Dashboard.Collectors.Cleanup]}}
  ]

# Configure the endpoint
config :dashboard, DashboardWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: DashboardWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Dashboard.PubSub,
  live_view: [signing_salt: "lCjCI+NL"]

# Configure the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :dashboard, Dashboard.Mailer, adapter: Swoosh.Adapters.Local

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
