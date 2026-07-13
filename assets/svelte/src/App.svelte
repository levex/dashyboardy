<script lang="ts">
  import { onMount } from 'svelte'
  import { api, type Layout, type LayoutWidget, type User } from './lib/api'
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
        const data = await api.layout()
        layout = data.layout
      }
    } finally {
      loading = false
    }
  })

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
        <p class="subtitle">Signed in as {user.email}</p>
      {/if}
    </div>
    <div class="actions">
      {#if user}
        <a class="button" href="/auth/logout">Sign out</a>
      {:else}
        <a class="button" href="/auth/google">Sign in with Google</a>
      {/if}
    </div>
  </header>

  {#if loading}
    <div class="center">Loading…</div>
  {:else if !user}
    <div class="center card">
      <h2>Welcome</h2>
      <p>Sign in with your Google account to view your dashboard.</p>
      <a class="button" href="/auth/google">Sign in with Google</a>
    </div>
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

  .actions .button,
  .button {
    background: var(--accent);
    border: none;
    border-radius: 8px;
    color: #081018;
    cursor: pointer;
    display: inline-block;
    font-weight: 600;
    padding: 0.55rem 0.9rem;
    text-decoration: none;
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
    gap: 0.75rem;
    justify-items: center;
    min-height: 50vh;
    text-align: center;
  }

  .card {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: 12px;
    margin: 0 auto;
    max-width: 420px;
    padding: 2rem;
  }

  .card h2 {
    color: var(--text);
    margin: 0;
  }
</style>
