# Personal Dashboard

Self-hosted personal dashboard aggregating GitHub, Redmine, RSS, and weather into a configurable widget layout.

## Stack

- **Backend:** Phoenix (Elixir)
- **Frontend:** Svelte 5
- **Database:** SQLite (WAL mode, Fly Volume in production)
- **Scheduler:** Quantum (no Oban)
- **Auth:** Google OAuth (single allowed account)
- **Deploy:** Fly.io

## Quick Start

```bash
# Install backend deps
mix setup

# Install frontend deps and build
mix assets.setup
mix assets.build

# Set environment variables (see .env.example)
export GOOGLE_CLIENT_ID=...
export GOOGLE_CLIENT_SECRET=...
export ALLOWED_EMAIL=you@example.com

# Start server
mix phx.server
```

Visit http://localhost:4000 and sign in with Google.

## Architecture

```
lib/dashboard/
  accounts/          # OAuth user
  activities/        # Unified activity model
  collectors/        # GitHub, Redmine, RSS, Weather, Cleanup
  scheduler.ex       # Quantum cron jobs
  github/            # Commit metadata
  redmine/           # Issue metadata
  rss/               # Feeds and entries
  weather/           # City readings
  widgets/           # Layout persistence

assets/svelte/       # Svelte SPA (built to priv/static)
```

See [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) for phased rollout.

## Collectors

| Collector | Interval | Retention |
|-----------|----------|-----------|
| GitHub (default repos) | 5 min | 90 days |
| GitHub (Boilerplate-Inc/app) | 2 min | 90 days |
| Redmine | 5 min | 180 days |
| RSS | 10 min | 30 days (saved items kept) |
| Weather | 20 min | 7 days |
| Cleanup | nightly 03:00 | — |

Collectors use a lock to prevent overlapping runs.

## Deployment

See `fly.toml` and `Dockerfile`. Requires a Fly Volume mounted at `/data`.

```bash
fly volumes create dashboard_data --size 1
fly secrets set SECRET_KEY_BASE=$(mix phx.gen.secret) ...
fly deploy
```
