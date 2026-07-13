<script lang="ts">
  import { api, relativeTime, type RssEntry } from '../api'

  let { refreshToken = 0 } = $props<{ refreshToken?: number }>()

  let filter = $state<'all' | 'unread' | 'saved'>('all')
  let localRefresh = $state(0)

  const entries = $derived.by(async (): Promise<RssEntry[]> => {
    refreshToken
    filter
    localRefresh
    try {
      return (
        await api.rss({
          unread: filter === 'unread',
          saved: filter === 'saved'
        })
      ).entries
    } catch {
      return []
    }
  })

  async function toggleRead(entry: RssEntry) {
    if (!entry.read) {
      await api.markRssRead(entry.id)
      localRefresh++
    }
  }

  async function toggleSaved(entry: RssEntry) {
    await api.markRssSaved(entry.id, !entry.saved)
    localRefresh++
  }
</script>

<div class="widget-toolbar">
  <button class="chip" class:active={filter === 'all'} onclick={() => (filter = 'all')}>All</button>
  <button class="chip" class:active={filter === 'unread'} onclick={() => (filter = 'unread')}>Unread</button>
  <button class="chip" class:active={filter === 'saved'} onclick={() => (filter = 'saved')}>Saved</button>
</div>

<ul class="widget-list">
  {#await entries then loadedEntries}
    {#each loadedEntries as entry (entry.id)}
      <li class={{ item: true, unread: !entry.read }}>
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
          <button
            class={{ save: true, saved: entry.saved }}
            onclick={() => toggleSaved(entry)}
            aria-label={entry.saved ? 'Remove from saved' : 'Save article'}
            aria-pressed={entry.saved}
          >
            {entry.saved ? '★' : '☆'}
          </button>
        </div>
        <div class="meta">{relativeTime(entry.published_at)}</div>
      </li>
    {:else}
      <li class="widget-empty">No feed entries yet</li>
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
    align-items: flex-start;
    display: flex;
    gap: 0.4rem;
    min-width: 0;
  }

  .title {
    color: var(--text-soft);
    flex: 1;
    font-size: 0.82rem;
    line-height: 1.45;
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
    border: 1px solid transparent;
    border-radius: 5px;
    color: var(--text-muted);
    cursor: pointer;
    flex-shrink: 0;
    font-size: 0.95rem;
    line-height: 1;
    padding: 0.18rem 0.25rem;
  }

  .save:hover {
    background: var(--surface-hover);
    color: var(--text-soft);
  }

  .save.saved {
    color: var(--warning);
  }

  .meta {
    color: var(--text-muted);
    font-size: 0.68rem;
    margin-top: 0.25rem;
  }
</style>
