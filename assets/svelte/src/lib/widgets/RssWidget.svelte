<script lang="ts">
  import { api, relativeTime, type RssEntry } from '../api'

  let { refreshToken = 0 } = $props<{ refreshToken?: number }>()

  let entries = $state<RssEntry[]>([])
  let filter = $state<'all' | 'unread' | 'saved'>('all')

  async function load() {
    try {
      const data = await api.rss({
        unread: filter === 'unread',
        saved: filter === 'saved'
      })
      entries = data.entries
    } catch {
      entries = []
    }
  }

  $effect(() => {
    refreshToken
    filter
    load()
  })

  async function toggleRead(entry: RssEntry) {
    if (!entry.read) {
      await api.markRssRead(entry.id)
      entry.read = true
    }
  }

  async function toggleSaved(entry: RssEntry) {
    const saved = !entry.saved
    await api.markRssSaved(entry.id, saved)
    entry.saved = saved
  }
</script>

<div class="toolbar">
  <button class:active={filter === 'all'} onclick={() => (filter = 'all')}>All</button>
  <button class:active={filter === 'unread'} onclick={() => (filter = 'unread')}>Unread</button>
  <button class:active={filter === 'saved'} onclick={() => (filter = 'saved')}>Saved</button>
</div>

<ul class="list">
  {#each entries as entry (entry.id)}
    <li class:unread={!entry.read}>
      <div class="row">
        <a class="title" href={entry.url} target="_blank" rel="noreferrer" onclick={() => toggleRead(entry)}>
          {entry.title}
        </a>
        <button class="save" class:saved={entry.saved} onclick={() => toggleSaved(entry)}>
          {entry.saved ? '★' : '☆'}
        </button>
      </div>
      <div class="meta">{relativeTime(entry.published_at)}</div>
    </li>
  {:else}
    <li class="empty">No feed entries yet</li>
  {/each}
</ul>

<style>
  .toolbar {
    display: flex;
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
  }

  button.active {
    background: var(--accent-soft);
    border-color: var(--accent);
    color: var(--accent);
  }

  .list {
    display: grid;
    gap: 0.75rem;
    list-style: none;
    margin: 0;
    padding: 0;
  }

  .row {
    align-items: start;
    display: flex;
    gap: 0.5rem;
    justify-content: space-between;
  }

  .title {
    color: var(--text);
    font-size: 0.9rem;
    text-decoration: none;
  }

  .unread .title {
    font-weight: 600;
  }

  .title:hover {
    color: var(--accent);
  }

  .save {
    border: none;
    color: var(--text-muted);
    font-size: 1rem;
    padding: 0;
  }

  .save.saved {
    color: #f5c542;
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
