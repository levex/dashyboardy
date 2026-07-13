# Implementation Plan

Phased rollout for the personal dashboard MVP and follow-on improvements.

## Phase 1 — Foundation (complete in this PR)

**Goal:** Runnable skeleton with schema, scheduler, and deploy config.

- [x] Phoenix API-only app with SQLite (`ecto_sqlite3`)
- [x] WAL mode, foreign keys, incremental vacuum pragmas
- [x] Unified `activities` table and source-specific tables
- [x] Quantum scheduler with non-overlapping collector lock
- [x] Collector modules: GitHub, Redmine, RSS, Weather, Cleanup
- [x] Retention policy in nightly cleanup job
- [x] Passkey (WebAuthn) auth with backup codes
- [x] Svelte 5 SPA with dark-mode dashboard widgets
- [x] Persisted widget layout (collapse state)
- [x] Fly.io `fly.toml` + `Dockerfile` with volume mount

**Verify locally:**

```bash
mix setup
mix assets.setup && mix assets.build
mix phx.server
```

## Phase 2 — Integration hardening

**Goal:** Reliable production data ingestion.

1. **GitHub App auth**
   - Replace PAT with GitHub App installation token (JWT → installation access token)
   - Store app ID, private key, installation ID as Fly secrets
   - Add rate-limit backoff and `If-None-Match` caching where applicable

2. **Redmine journals**
   - Fetch `/issues/:id.json?include=journals` for real status-change summaries
   - Parse journal details for assignee/status transitions
   - Filter "assigned to me" using Redmine user ID instead of display name

3. **RSS robustness**
   - Per-feed ETag/Last-Modified headers
   - Graceful handling of malformed feeds
   - Admin UI to add/disable feeds (nice-to-have precursor)

4. **Weather enrichment**
   - Add wind and "feels like" from Open-Meteo
   - Optional fallback provider

## Phase 3 — Dashboard UX

**Goal:** Daily-driver desktop experience.

1. **Layout editor**
   - Resize widgets (drag handles)
   - Persist position/size changes via `/api/layout`
   - Optional: drag-and-drop reorder (nice-to-have)

2. **Read/unread polish**
   - Bulk mark-read for RSS
   - Unread counts in widget headers
   - Keyboard shortcuts (`j/k`, `s`, `/`) — nice-to-have

3. **Timeline improvements**
   - Group by day
   - Deep links to source widgets
   - Source-specific icons

4. **Auto-refresh**
   - Poll API every 60s while tab is visible
   - `document.visibilityState` aware

## Phase 4 — Operations

**Goal:** Low-overhead self-hosting on Fly.io.

1. **Secrets checklist**
   ```bash
   fly secrets set \
     SECRET_KEY_BASE=... \
     WEBAUTHN_ORIGIN=https://your-app.fly.dev \
     WEBAUTHN_RP_ID=your-app.fly.dev \
     GITHUB_TOKEN=... \
     REDMINE_URL=... \
     REDMINE_API_KEY=... \
     REDMINE_SSO_BYPASS_HEADER=... \
     REDMINE_ASSIGNEE_NAME=...
   ```

2. **Volume + deploy**
   ```bash
   fly volumes create dashboard_data --region fra --size 1
   fly deploy
   ```

3. **Health checks**
   - Add `/api/health` (DB ping + last collector timestamps)
   - Fly HTTP check on health endpoint

4. **Observability**
   - Structured logs for collector runs
   - Optional: Fly Logship / Grafana

## Phase 5 — Nice-to-haves (post-MVP)

| Feature | Notes |
|---------|-------|
| Search | SQLite FTS5 over activities + RSS |
| Browser notifications | Web Push for assigned Redmine tickets |
| CI status | GitHub Checks API per repo |
| Redmine mentions | Filter journals for `@me` |
| Widget drag-and-drop | `svelte-dnd-action` or grid library |
| PWA | Service worker + manifest |
| Mobile layout | Single-column breakpoint |
| Custom RSS feeds | CRUD API + settings page |

## Architecture Reference

```
Browser (Svelte)
    │  session cookie
    ▼
Phoenix Endpoint
    ├── /api/auth/*    → WebAuthn registration/login + backup codes
    ├── /api/*         → JSON controllers (secrets never exposed)
    └── /*             → priv/static SPA

Dashboard.Scheduler (Quantum)
    └── Dashboard.Collectors.Runner
            └── Dashboard.Collectors.Lock (ETS)
                    ├── GitHub
                    ├── Redmine
                    ├── RSS
                    ├── Weather
                    └── Cleanup

Dashboard.Repo (SQLite on Fly Volume)
    ├── activities      ← unified timeline
    ├── github_commits
    ├── redmine_issues
    ├── rss_feeds / rss_entries
    ├── weather_readings
    └── widget_layouts
```

## Collector Schedule

| Job | Cron | Lock key |
|-----|------|----------|
| GitHub (all repos) | `*/5 * * * *` | `github` |
| GitHub (Boilerplate-Inc/app) | `*/2 * * * *` | `github:Boilerplate-Inc/app` |
| Redmine | `*/5 * * * *` | `redmine` |
| RSS | `*/10 * * * *` | `rss` |
| Weather | `*/20 * * * *` | `weather` |
| Cleanup | `0 3 * * *` | `cleanup` |

## Retention

| Source | Days | Saved items |
|--------|------|-------------|
| GitHub | 90 | n/a |
| RSS | 30 | never deleted |
| Weather | 7 | n/a |
| Redmine | 180 | n/a |

## Risk Notes

- **GitHub rate limits:** Use authenticated requests; App auth preferred for production.
- **Redmine SSO:** Bypass header must match reverse-proxy config exactly (`Name: Value` or separate env vars).
- **SQLite on Fly:** Single machine + volume = simple ops; not horizontally scalable without redesign.
- **WebAuthn RP ID:** `WEBAUTHN_RP_ID` must match your deployment hostname (e.g. `your-app.fly.dev`).
