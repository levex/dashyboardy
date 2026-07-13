<script lang="ts">
  import { onMount } from 'svelte'
  import { api, type Layout, type LayoutWidget } from './lib/api'
  import { authApi, type User } from './lib/webauthn'
  import LoginPanel from './lib/LoginPanel.svelte'
  import Widget from './lib/Widget.svelte'
  import ClockWidget from './lib/widgets/ClockWidget.svelte'
  import WeatherWidget from './lib/widgets/WeatherWidget.svelte'
  import GitHubWidget from './lib/widgets/GitHubWidget.svelte'
  import RedmineWidget from './lib/widgets/RedmineWidget.svelte'
  import RssWidget from './lib/widgets/RssWidget.svelte'
  import TimelineWidget from './lib/widgets/TimelineWidget.svelte'
  import PullDataButton from './lib/PullDataButton.svelte'

  let user = $state<User | null>(null)
  let layout = $state<Layout | null>(null)
  let loading = $state(true)
  let refreshToken = $state(0)

  const titles: Record<string, string> = {
    clock: 'Time',
    weather: 'Weather',
    github: 'GitHub',
    redmine: 'Redmine',
    rss: 'RSS',
    timeline: 'Activity'
  }

  onMount(async () => {
    try {
      const me = await api.me()
      if (me.authenticated && me.user) {
        user = me.user
        await loadLayout()
      }
    } finally {
      loading = false
    }
  })

  async function loadLayout() {
    const data = await api.layout()
    layout = data.layout
  }

  async function handleAuth(nextUser: User) {
    user = nextUser
    await loadLayout()
  }

  async function signOut() {
    await authApi.logout()
    user = null
    layout = null
  }

  function toggleWidget(widget: LayoutWidget) {
    if (!layout) return
    layout = {
      ...layout,
      widgets: layout.widgets.map((item) =>
        item.id === widget.id ? { ...item, collapsed: !item.collapsed } : item
      )
    }
    api.saveLayout(layout).catch(() => undefined)
  }

  function updateWidgetSettings(widgetId: string, settings: Record<string, string>) {
    if (!layout) return
    layout = {
      ...layout,
      widgets: layout.widgets.map((item) =>
        item.id === widgetId
          ? { ...item, settings: { ...item.settings, ...settings } }
          : item
      )
    }
    api.saveLayout(layout).catch(() => undefined)
  }

  function widgetStyle(widget: LayoutWidget) {
    return `grid-column: ${widget.x + 1} / span ${widget.w}; grid-row: ${widget.y + 1} / span ${widget.h};`
  }

  function githubWidget() {
    return layout?.widgets.find((w) => w.id === 'github')
  }
</script>

<div class="app">
  <header class="topbar">
    <div class="brand">
      <span class="brand-mark" aria-hidden="true"></span>
      <div class="brand-copy">
        <p class="eyebrow">Personal workspace</p>
        <h1>Dashboard</h1>
      </div>
    </div>
    <div class="actions">
      {#if user}
        <div class="profile" title={user.display_name}>
          <span class="avatar" aria-hidden="true">{user.display_name.slice(0, 1).toUpperCase()}</span>
          <span class="profile-name">{user.display_name}</span>
        </div>
        <PullDataButton onPulled={() => refreshToken++} />
        <button class="btn-signout" onclick={signOut}>Sign out</button>
      {/if}
    </div>
  </header>

  {#if loading}
    <div class="center">Loading…</div>
  {:else if !user}
    <LoginPanel onSuccess={handleAuth} />
  {:else if layout}
    <div class="dashboard-heading">
      <div>
        <p class="eyebrow">Overview</p>
        <h2>Your day at a glance</h2>
      </div>
      <p class="dashboard-note">Live data from your connected services</p>
    </div>
    <main class="dashboard-grid" aria-label="Dashboard widgets">
      {#each layout.widgets as widget (widget.id)}
        <div class="widget-cell" style={widgetStyle(widget)}>
          <Widget
            title={titles[widget.id] ?? widget.id}
            collapsed={widget.collapsed}
            onToggle={() => toggleWidget(widget)}
          >
            {#if widget.id === 'clock'}
              <ClockWidget />
            {:else if widget.id === 'weather'}
              <WeatherWidget {refreshToken} />
            {:else if widget.id === 'github'}
              <GitHubWidget
                {refreshToken}
                selectedRepo={githubWidget()?.settings?.repo ?? 'all'}
                onRepoChange={(repo) => updateWidgetSettings('github', { repo })}
              />
            {:else if widget.id === 'redmine'}
              <RedmineWidget {refreshToken} />
            {:else if widget.id === 'rss'}
              <RssWidget {refreshToken} />
            {:else if widget.id === 'timeline'}
              <TimelineWidget {refreshToken} />
            {/if}
          </Widget>
        </div>
      {/each}
    </main>
  {/if}
</div>

<style>
  .app {
    margin: 0 auto;
    max-width: 1540px;
    min-height: 100vh;
    padding: 0 1.75rem 2rem;
    width: 100%;
  }

  .topbar {
    align-items: center;
    border-bottom: 1px solid var(--border);
    display: flex;
    gap: 1.25rem;
    justify-content: space-between;
    min-height: 74px;
  }

  .brand {
    align-items: center;
    display: flex;
    gap: 0.75rem;
    min-width: 0;
  }

  .brand-mark {
    background: var(--accent);
    border-radius: 3px;
    box-shadow: 0 0 18px rgba(143, 168, 255, 0.28);
    height: 26px;
    width: 4px;
  }

  .brand-copy {
    min-width: 0;
  }

  h1 {
    font-size: 1.05rem;
    font-weight: 650;
    letter-spacing: -0.015em;
    margin: 0;
  }

  .eyebrow {
    color: var(--text-muted);
    font-size: 0.65rem;
    font-weight: 650;
    letter-spacing: 0.11em;
    margin: 0 0 0.08rem;
    text-transform: uppercase;
  }

  .actions {
    align-items: center;
    display: flex;
    flex-shrink: 0;
    gap: 0.6rem;
    justify-content: flex-end;
    min-width: 0;
  }

  .profile {
    align-items: center;
    display: flex;
    gap: 0.5rem;
    margin-right: 0.35rem;
    max-width: 220px;
    min-width: 0;
  }

  .avatar {
    align-items: center;
    background: var(--accent-soft);
    border: 1px solid rgba(143, 168, 255, 0.25);
    border-radius: 50%;
    color: var(--accent);
    display: flex;
    flex: 0 0 auto;
    font-size: 0.7rem;
    font-weight: 700;
    height: 28px;
    justify-content: center;
    width: 28px;
  }

  .profile-name {
    color: var(--text-soft);
    font-size: 0.78rem;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .btn-signout {
    background: transparent;
    border: 1px solid transparent;
    border-radius: 7px;
    color: var(--text-muted);
    cursor: pointer;
    font-size: 0.75rem;
    font-weight: 600;
    padding: 0.45rem 0.6rem;
    white-space: nowrap;
  }

  .btn-signout:hover {
    background: var(--surface-raised);
    border-color: var(--border);
    color: var(--text);
  }

  .dashboard-heading {
    align-items: end;
    display: flex;
    gap: 1rem;
    justify-content: space-between;
    padding: 1.6rem 0 1rem;
  }

  .dashboard-heading h2 {
    font-size: clamp(1.35rem, 2.2vw, 1.75rem);
    font-weight: 620;
    letter-spacing: -0.035em;
    line-height: 1.2;
    margin: 0;
  }

  .dashboard-note {
    color: var(--text-muted);
    font-size: 0.75rem;
    margin: 0 0 0.15rem;
  }

  .dashboard-grid {
    display: grid;
    gap: 1rem;
    grid-auto-rows: var(--row-height);
    grid-template-columns: repeat(12, minmax(0, 1fr));
    isolation: isolate;
    width: 100%;
  }

  .widget-cell {
    display: flex;
    min-height: 0;
    min-width: 0;
  }

  .widget-cell :global(.widget) {
    flex: 1;
    width: 100%;
  }

  .center {
    align-items: center;
    color: var(--text-muted);
    display: grid;
    min-height: calc(100vh - 74px);
    place-items: center;
  }

  @media (max-width: 1100px) {
    .widget-cell {
      grid-column: 1 / -1 !important;
      grid-row: auto !important;
      min-height: min(360px, 48vh);
    }

    .dashboard-grid {
      grid-auto-rows: auto;
      grid-template-columns: minmax(0, 1fr);
    }
  }

  @media (max-width: 720px) {
    .app {
      padding: 0 1rem 1.25rem;
    }

    .topbar {
      align-items: flex-start;
      flex-direction: column;
      gap: 0.75rem;
      padding: 1rem 0;
    }

    .actions {
      justify-content: flex-start;
      width: 100%;
    }

    .profile {
      margin-right: auto;
    }

    .profile-name {
      display: none;
    }

    .dashboard-heading {
      align-items: flex-start;
      flex-direction: column;
      padding-top: 1.25rem;
    }

    .dashboard-note {
      display: none;
    }
  }

  @media (max-width: 460px) {
    .actions {
      flex-wrap: wrap;
    }

    .profile {
      display: none;
    }
  }
</style>
