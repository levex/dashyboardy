defmodule Dashboard.Repo.Migrations.CreateCoreTables do
  use Ecto.Migration

  def change do
    execute("PRAGMA journal_mode = WAL")
    execute("PRAGMA foreign_keys = ON")
    execute("PRAGMA auto_vacuum = INCREMENTAL")

    create table(:users) do
      add :email, :string, null: false
      add :name, :string
      add :google_id, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])
    create unique_index(:users, [:google_id])

    create table(:activities) do
      add :source, :string, null: false
      add :source_instance, :string, null: false
      add :external_id, :string, null: false
      add :type, :string, null: false
      add :title, :string, null: false
      add :summary, :text
      add :author, :string
      add :url, :string
      add :occurred_at, :utc_datetime, null: false
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:activities, [:source, :source_instance, :external_id])
    create index(:activities, [:occurred_at])
    create index(:activities, [:source])

    create table(:github_commits) do
      add :repo, :string, null: false
      add :sha, :string, null: false
      add :author, :string
      add :message, :text, null: false
      add :committed_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:github_commits, [:repo, :sha])
    create index(:github_commits, [:committed_at])

    create table(:redmine_issues) do
      add :issue_id, :integer, null: false
      add :title, :string, null: false
      add :status, :string
      add :assignee, :string
      add :updated_at_source, :utc_datetime, null: false
      add :journal_summaries, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:redmine_issues, [:issue_id])
    create index(:redmine_issues, [:updated_at_source])
    create index(:redmine_issues, [:assignee])

    create table(:rss_feeds) do
      add :name, :string, null: false
      add :url, :string, null: false
      add :enabled, :boolean, default: true, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:rss_feeds, [:url])

    create table(:rss_entries) do
      add :feed_id, references(:rss_feeds, on_delete: :delete_all), null: false
      add :external_id, :string, null: false
      add :title, :string, null: false
      add :url, :string, null: false
      add :published_at, :utc_datetime
      add :summary, :text
      add :read, :boolean, default: false, null: false
      add :saved, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:rss_entries, [:feed_id, :external_id])
    create index(:rss_entries, [:published_at])
    create index(:rss_entries, [:read])
    create index(:rss_entries, [:saved])

    create table(:weather_readings) do
      add :city, :string, null: false
      add :temperature, :float
      add :conditions, :string
      add :humidity, :integer
      add :metadata, :map, default: %{}
      add :recorded_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:weather_readings, [:city, :recorded_at])

    create table(:widget_layouts) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :layout, :map, null: false, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:widget_layouts, [:user_id])
  end
end
