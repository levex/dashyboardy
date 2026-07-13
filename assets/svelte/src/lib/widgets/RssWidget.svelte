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

<div class="widget-toolbar">
  <button class="chip" class:active={filter === 'all'} onclick={() => (filter = 'all')}>All</button>
  <button class="chip" class:active={filter === 'unread'} onclick={() => (filter = 'unread')}>Unread</button>
  <button class="chip" class:active={filter === 'saved'} onclick={() => (filter = 'saved')}>Saved</button>
</div>

<ul class="widget-list">
  {#each entries as entry (entry.id)}
    <li class="item" class:unread={!entry.read}>
      <div class="row">
        <a
          class="title line-clamp-2"
          href={entry.url}
          target="_blank"
          rel="noreferrer"
          onclick={() => toggleRead(entry)}
        >
          {entry.title}
        </a>
        <button class="save" class:saved={entry.saved} onclick={() => toggleSaved(entry)} aria-label="Save">
          {entry.saved ? '★' : '☆'}
        </button>
      </div>
      <div class="meta">{relativeTime(entry.published_at)}</div>
    </li>
  {:else}
    <li class="widget-empty">No feed entries yet</li>
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
    align-items: flex-start;
    display: flex;
    gap: 0.4rem;
    min-width: 0;
  }

  .title {
    color: var(--text);
    flex: 1;
    font-size: 0.85rem;
    min-width: 0;
    text-decoration: none;
  }

  .unread .title {
    font-weight: 600;
  }

  .title:hover {
    color: var(--accent);
  }

  .save {
    background: none;
    border: none;
    color: var(--text-muted);
    cursor: pointer;
    flex-shrink: 0;
    font-size: 0.95rem;
    padding: 0;
  }

  .save.saved {
    color: #f5c542;
  }

  .meta {
    color: var(--text-muted);
    font-size: 0.72rem;
    margin-top: 0.15rem;
  }
</style>
