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

  let user = $state<User | null>(null)
  let layout = $state<Layout | null>(null)
  let loading = $state(true)

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

  function widgetStyle(widget: LayoutWidget) {
    return `grid-column: span ${widget.w}; grid-row: span ${widget.h};`
  }
</script>

<div class="app">
  <header class="topbar">
    <div>
      <h1>Personal Dashboard</h1>
      {#if user}
        <p class="subtitle">{user.display_name}</p>
      {/if}
    </div>
    <div class="actions">
      {#if user}
        <button class="button" onclick={signOut}>Sign out</button>
      {/if}
    </div>
  </header>

  {#if loading}
    <div class="center">Loading…</div>
  {:else if !user}
    <LoginPanel onSuccess={handleAuth} />
  {:else if layout}
    <main class="grid" style={`--columns: ${layout.columns}`}>
      {#each layout.widgets as widget (widget.id)}
        <div style={widgetStyle(widget)}>
          <Widget
            title={titles[widget.id] ?? widget.id}
            collapsed={widget.collapsed}
            onToggle={() => toggleWidget(widget)}
          >
            {#if widget.id === 'clock'}
              <ClockWidget />
            {:else if widget.id === 'weather'}
              <WeatherWidget />
            {:else if widget.id === 'github'}
              <GitHubWidget />
            {:else if widget.id === 'redmine'}
              <RedmineWidget />
            {:else if widget.id === 'rss'}
              <RssWidget />
            {:else if widget.id === 'timeline'}
              <TimelineWidget />
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
    max-width: 1400px;
    min-height: 100vh;
    padding: 1.25rem;
  }

  .topbar {
    align-items: center;
    display: flex;
    justify-content: space-between;
    margin-bottom: 1.25rem;
  }

  h1 {
    font-size: 1.4rem;
    margin: 0;
  }

  .subtitle {
    color: var(--text-muted);
    font-size: 0.85rem;
    margin: 0.2rem 0 0;
  }

  .button {
    background: var(--accent);
    border: none;
    border-radius: 8px;
    color: #081018;
    cursor: pointer;
    display: inline-block;
    font-weight: 600;
    padding: 0.55rem 0.9rem;
  }

  .grid {
    display: grid;
    gap: 1rem;
    grid-auto-rows: 80px;
    grid-template-columns: repeat(var(--columns), minmax(0, 1fr));
  }

  .center {
    align-items: center;
    color: var(--text-muted);
    display: grid;
    min-height: 50vh;
    place-items: center;
  }
</style>
