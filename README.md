# Personal Dashboard

Self-hosted personal dashboard aggregating GitHub, Redmine, RSS, and weather into a configurable widget layout.

## Stack

- **Backend:** Phoenix (Elixir)
- **Frontend:** Svelte 5
- **Database:** SQLite (WAL mode, Fly Volume in production)
- **Scheduler:** Quantum (no Oban)
- **Auth:** Passkeys (WebAuthn) with one-time backup codes
- **Deploy:** Fly.io

## Quick Start

```bash
# Install backend deps
mix setup

# Install frontend deps and build
mix assets.setup
mix assets.build

# Set environment variables (see .env.example)

# Start server — first visit will prompt passkey enrollment
mix phx.server
```

Visit http://localhost:4000 and enroll a passkey on first launch.

## Authentication

The dashboard uses **passkeys** (WebAuthn) — no Google account or password required.

1. **First visit:** enroll a passkey (Touch ID, Windows Hello, YubiKey, etc.)
2. **You'll receive 10 backup codes** — save them somewhere safe
3. **Later visits:** sign in with your passkey, or use a backup code if needed

Configure WebAuthn for production:

```bash
WEBAUTHN_ORIGIN=https://your-app.fly.dev
WEBAUTHN_RP_ID=your-app.fly.dev
```

The Redmine SSO bypass header is unrelated — it only lets the **server collector** reach Redmine behind SSO.

## Architecture

```
lib/dashboard/
  accounts/          # Dashboard owner
  auth/              # Passkey credentials + backup codes
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
fly secrets set \
  SECRET_KEY_BASE=... \
  WEBAUTHN_ORIGIN=https://your-app.fly.dev \
  WEBAUTHN_RP_ID=your-app.fly.dev \
  GITHUB_TOKEN=... \
fly deploy
```
