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
      <h1>Personal Dashboard</h1>
      {#if user}
        <p class="subtitle">{user.display_name}</p>
      {/if}
    </div>
    <div class="actions">
      {#if user}
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
    <main class="dashboard-grid">
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
    max-width: 1440px;
    min-height: 100vh;
    padding: 1rem 1.25rem 1.5rem;
    width: 100%;
  }

  .topbar {
    align-items: flex-start;
    display: flex;
    flex-wrap: wrap;
    gap: 0.75rem 1rem;
    justify-content: space-between;
    margin-bottom: 1rem;
  }

  .brand {
    min-width: 0;
  }

  h1 {
    font-size: 1.25rem;
    font-weight: 700;
    letter-spacing: -0.02em;
    margin: 0;
  }

  .subtitle {
    color: var(--text-muted);
    font-size: 0.8rem;
    margin: 0.15rem 0 0;
  }

  .actions {
    align-items: center;
    display: flex;
    flex-shrink: 0;
    flex-wrap: wrap;
    gap: 0.5rem;
    justify-content: flex-end;
  }

  .btn-signout {
    background: var(--accent);
    border: none;
    border-radius: 8px;
    color: #081018;
    cursor: pointer;
    font-size: 0.85rem;
    font-weight: 600;
    padding: 0.5rem 0.85rem;
    white-space: nowrap;
  }

  .dashboard-grid {
    display: grid;
    gap: 0.85rem;
    grid-auto-rows: var(--row-height);
    grid-template-columns: repeat(12, minmax(0, 1fr));
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
    min-height: 50vh;
    place-items: center;
  }

  @media (max-width: 1100px) {
    .dashboard-grid {
      grid-template-columns: repeat(6, minmax(0, 1fr));
    }

    .widget-cell {
      grid-column: 1 / -1 !important;
      grid-row: auto !important;
      min-height: 220px;
    }
  }
</style>
