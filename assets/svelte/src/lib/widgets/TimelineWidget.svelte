<script lang="ts">
  import { api, relativeTime, type Activity } from '../api'

  let { refreshToken = 0 } = $props<{ refreshToken?: number }>()

  let activities = $state<Activity[]>([])
  let source = $state<string>('all')

  const sources = ['all', 'github', 'redmine', 'rss']

  async function load() {
    try {
      const data = await api.timeline(source === 'all' ? undefined : source)
      activities = data.activities
    } catch {
      activities = []
    }
  }

  $effect(() => {
    refreshToken
    source
    load()
  })
</script>

<div class="widget-toolbar">
  {#each sources as item (item)}
    <button class="chip" class:active={source === item} onclick={() => (source = item)}>{item}</button>
  {/each}
</div>

<ul class="widget-list">
  {#each activities as activity (activity.id)}
    <li class="item">
      <div class="row">
        <span class="badge">{activity.source}</span>
        <span class="time">{relativeTime(activity.occurred_at)}</span>
      </div>
      {#if activity.url}
        <a class="title line-clamp-2" href={activity.url} target="_blank" rel="noreferrer">{activity.title}</a>
      {:else}
        <div class="title line-clamp-2">{activity.title}</div>
      {/if}
      <div class="meta truncate">{activity.author ?? activity.source_instance}</div>
    </li>
  {:else}
    <li class="widget-empty">No activity yet</li>
  {/each}
</ul>

<style>
  .item {
    border-bottom: 1px solid var(--border);
    padding-bottom: 0.65rem;
  }

  .item:last-child {
    border-bottom: none;
  }

  .row {
    display: flex;
    justify-content: space-between;
    gap: 0.5rem;
  }

  .badge {
    background: var(--accent-soft);
    border-radius: 999px;
    color: var(--accent);
    font-size: 0.65rem;
    font-weight: 600;
    padding: 0.1rem 0.45rem;
    text-transform: uppercase;
  }

  .time {
    color: var(--text-muted);
    flex-shrink: 0;
    font-size: 0.72rem;
  }

  .title {
    color: var(--text);
    display: block;
    font-size: 0.85rem;
    margin-top: 0.2rem;
    text-decoration: none;
  }

  .title:hover {
    color: var(--accent);
  }

  .meta {
    color: var(--text-muted);
    font-size: 0.72rem;
    margin-top: 0.15rem;
  }
</style>
