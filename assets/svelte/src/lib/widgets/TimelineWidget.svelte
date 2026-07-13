<script lang="ts">
  import { api, relativeTime, type Activity } from '../api'

  let { refreshToken = 0 } = $props<{ refreshToken?: number }>()

  let source = $state<string>('all')

  const sources = ['all', 'github', 'redmine', 'rss']

  const activities = $derived.by(async (): Promise<Activity[]> => {
    refreshToken
    source
    try {
      return (await api.timeline(source === 'all' ? undefined : source)).activities
    } catch {
      return []
    }
  })
</script>

<div class="widget-toolbar">
  {#each sources as item (item)}
    <button class="chip" class:active={source === item} onclick={() => (source = item)}>{item}</button>
  {/each}
</div>

<ul class="widget-list">
  {#await activities then loadedActivities}
    {#each loadedActivities as activity (activity.id)}
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
  {/await}
</ul>

<style>
  .item {
    border-bottom: 1px solid var(--border);
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
    border: 1px solid rgba(143, 168, 255, 0.2);
    border-radius: 999px;
    color: var(--accent);
    font-size: 0.62rem;
    font-weight: 650;
    padding: 0.12rem 0.4rem;
    text-transform: uppercase;
  }

  .time {
    color: var(--text-muted);
    flex-shrink: 0;
    font-size: 0.72rem;
  }

  .title {
    color: var(--text-soft);
    display: block;
    font-size: 0.82rem;
    line-height: 1.45;
    margin-top: 0.35rem;
    text-decoration: none;
  }

  .title:hover {
    color: var(--accent);
  }

  .meta {
    color: var(--text-muted);
    font-size: 0.68rem;
    margin-top: 0.25rem;
  }
</style>
