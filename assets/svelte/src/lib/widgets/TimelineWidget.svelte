<script lang="ts">
  import { api, relativeTime, type Activity } from '../api'
  import { onMount } from 'svelte'

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

  onMount(load)

  $effect(() => {
    source
    load()
  })
</script>

<div class="toolbar">
  {#each sources as item}
    <button class:active={source === item} onclick={() => (source = item)}>{item}</button>
  {/each}
</div>

<ul class="list">
  {#each activities as activity}
    <li>
      <div class="row">
        <span class="badge">{activity.source}</span>
        <span class="time">{relativeTime(activity.occurred_at)}</span>
      </div>
      {#if activity.url}
        <a class="title" href={activity.url} target="_blank" rel="noreferrer">{activity.title}</a>
      {:else}
        <div class="title">{activity.title}</div>
      {/if}
      {#if activity.author}
        <div class="meta">{activity.author} · {activity.source_instance}</div>
      {:else}
        <div class="meta">{activity.source_instance}</div>
      {/if}
    </li>
  {:else}
    <li class="empty">No activity yet</li>
  {/each}
</ul>

<style>
  .toolbar {
    display: flex;
    flex-wrap: wrap;
    gap: 0.5rem;
    margin-bottom: 0.75rem;
  }

  button {
    background: transparent;
    border: 1px solid var(--border);
    border-radius: 999px;
    color: var(--text-muted);
    cursor: pointer;
    font-size: 0.75rem;
    padding: 0.25rem 0.65rem;
    text-transform: capitalize;
  }

  button.active {
    background: var(--accent-soft);
    border-color: var(--accent);
    color: var(--accent);
  }

  .list {
    display: grid;
    gap: 0.85rem;
    list-style: none;
    margin: 0;
    padding: 0;
  }

  .row {
    display: flex;
    justify-content: space-between;
  }

  .badge {
    background: var(--accent-soft);
    border-radius: 999px;
    color: var(--accent);
    font-size: 0.7rem;
    font-weight: 600;
    padding: 0.1rem 0.5rem;
    text-transform: uppercase;
  }

  .time {
    color: var(--text-muted);
    font-size: 0.75rem;
  }

  .title {
    color: var(--text);
    display: block;
    font-size: 0.9rem;
    margin-top: 0.2rem;
    text-decoration: none;
  }

  .title:hover {
    color: var(--accent);
  }

  .meta {
    color: var(--text-muted);
    font-size: 0.75rem;
    margin-top: 0.15rem;
  }

  .empty {
    color: var(--text-muted);
  }
</style>
