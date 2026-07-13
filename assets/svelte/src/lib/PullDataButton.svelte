<script lang="ts">
  import { api, type CollectorPullResult } from './api'

  let { onPulled } = $props<{
    onPulled?: () => void
  }>()

  let pulling = $state(false)
  let results = $state<CollectorPullResult[] | null>(null)
  let pulledAt = $state<string | null>(null)
  let open = $state(false)

  async function pull() {
    pulling = true
    results = null
    try {
      const data = await api.pull()
      results = data.results
      pulledAt = data.pulled_at
      open = true
      onPulled?.()
    } catch {
      results = [
        {
          source: 'system',
          status: 'error',
          message: 'Pull request failed',
          failures: []
        }
      ]
      open = true
    } finally {
      pulling = false
    }
  }

  const hasProblems = $derived(
    results?.some((r) => r.status === 'error' || r.status === 'partial' || r.status === 'skipped') ??
      false
  )

  function statusLabel(status: CollectorPullResult['status']) {
    switch (status) {
      case 'ok':
        return 'OK'
      case 'partial':
        return 'Partial'
      case 'error':
        return 'Failed'
      case 'skipped':
        return 'Skipped'
      default:
        return status
    }
  }
</script>

<div class="pull">
  <button class="button" disabled={pulling} onclick={pull}>
    {pulling ? 'Pulling…' : 'Pull data'}
  </button>

  {#if results}
    <button
      class="status-toggle"
      class:warn={hasProblems}
      onclick={() => (open = !open)}
      aria-expanded={open}
    >
      {hasProblems ? 'Some sources failed' : 'All sources OK'}
    </button>
  {/if}

  {#if open && results}
    <div class="panel">
      {#if pulledAt}
        <p class="meta">Last pull: {new Date(pulledAt).toLocaleString()}</p>
      {/if}
      <ul>
        {#each results as result (result.source)}
          <li class={result.status}>
            <div class="row">
              <span class="source">{result.source}</span>
              <span class="badge">{statusLabel(result.status)}</span>
            </div>
            <p class="message">{result.message}</p>
            {#if result.failures.length > 0}
              <ul class="failures">
                {#each result.failures as failure (failure.name)}
                  <li><strong>{failure.name}:</strong> {failure.error}</li>
                {/each}
              </ul>
            {/if}
          </li>
        {/each}
      </ul>
    </div>
  {/if}
</div>

<style>
  .pull {
    align-items: center;
    display: flex;
    flex-wrap: wrap;
    gap: 0.5rem;
    position: relative;
  }

  .button {
    background: transparent;
    border: 1px solid var(--border);
    border-radius: 8px;
    color: var(--text);
    cursor: pointer;
    font-size: 0.85rem;
    font-weight: 600;
    padding: 0.5rem 0.75rem;
  }

  .button:disabled {
    cursor: not-allowed;
    opacity: 0.6;
  }

  .status-toggle {
    background: rgba(93, 214, 192, 0.12);
    border: 1px solid var(--accent);
    border-radius: 999px;
    color: var(--accent);
    cursor: pointer;
    font-size: 0.75rem;
    padding: 0.25rem 0.6rem;
  }

  .status-toggle.warn {
    background: rgba(255, 143, 143, 0.12);
    border-color: #ff8f8f;
    color: #ff8f8f;
  }

  .panel {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: 10px;
    box-shadow: 0 8px 24px rgba(0, 0, 0, 0.35);
    margin-top: 0.35rem;
    padding: 0.75rem;
    position: absolute;
    right: 0;
    top: 100%;
    width: min(360px, 90vw);
    z-index: 20;
  }

  .meta {
    color: var(--text-muted);
    font-size: 0.75rem;
    margin: 0 0 0.5rem;
  }

  ul {
    display: grid;
    gap: 0.65rem;
    list-style: none;
    margin: 0;
    padding: 0;
  }

  .row {
    align-items: center;
    display: flex;
    justify-content: space-between;
  }

  .source {
    font-weight: 600;
    text-transform: capitalize;
  }

  .badge {
    font-size: 0.7rem;
    font-weight: 600;
    text-transform: uppercase;
  }

  .ok .badge {
    color: var(--accent);
  }

  .partial .badge,
  .skipped .badge {
    color: #f5c542;
  }

  .error .badge {
    color: #ff8f8f;
  }

  .message {
    color: var(--text-muted);
    font-size: 0.8rem;
    margin: 0.2rem 0 0;
  }

  .failures {
    color: var(--text-muted);
    font-size: 0.75rem;
    margin: 0.35rem 0 0;
    padding-left: 1rem;
  }
</style>
