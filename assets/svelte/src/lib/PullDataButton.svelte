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
    <span class:spinning={pulling} class="pull-icon" aria-hidden="true">↻</span>
    {pulling ? 'Syncing…' : 'Sync data'}
  </button>

  {#if results}
    <button
      class={{ 'status-toggle': true, warn: hasProblems }}
      onclick={() => (open = !open)}
      aria-expanded={open}
    >
      <span class="status-dot" aria-hidden="true"></span>
      {hasProblems ? 'Needs attention' : 'Up to date'}
    </button>
  {/if}

  {#if open && results}
    <div class="panel" aria-live="polite">
      {#if pulledAt}
        <p class="meta">Last synced {new Date(pulledAt).toLocaleString()}</p>
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
    gap: 0.4rem;
    min-width: 0;
    position: relative;
  }

  .button {
    align-items: center;
    background: var(--accent);
    border: 1px solid var(--accent);
    border-radius: 7px;
    color: #10131d;
    cursor: pointer;
    display: inline-flex;
    font-size: 0.75rem;
    font-weight: 700;
    gap: 0.4rem;
    padding: 0.45rem 0.65rem;
    white-space: nowrap;
  }

  .button:hover:not(:disabled) {
    background: var(--accent-hover);
    border-color: var(--accent-hover);
  }

  .button:disabled {
    cursor: not-allowed;
    opacity: 0.65;
  }

  .pull-icon {
    font-size: 0.95rem;
    line-height: 1;
  }

  .pull-icon.spinning {
    animation: spin 900ms linear infinite;
  }

  .status-toggle {
    align-items: center;
    background: transparent;
    border: 1px solid transparent;
    border-radius: 999px;
    color: var(--text-muted);
    cursor: pointer;
    display: inline-flex;
    font-size: 0.68rem;
    gap: 0.35rem;
    padding: 0.35rem 0.45rem;
    white-space: nowrap;
  }

  .status-toggle:hover {
    background: var(--surface-raised);
    border-color: var(--border);
    color: var(--text-soft);
  }

  .status-dot {
    background: var(--accent);
    border-radius: 50%;
    height: 6px;
    width: 6px;
  }

  .status-toggle.warn {
    color: var(--danger);
  }

  .status-toggle.warn .status-dot {
    background: var(--danger);
  }

  .panel {
    background: #15171a;
    border: 1px solid var(--border-strong);
    border-radius: 12px;
    box-shadow: 0 20px 60px rgba(0, 0, 0, 0.45);
    margin-top: 0.5rem;
    max-height: min(60vh, 420px);
    overflow: auto;
    padding: 0.85rem;
    position: absolute;
    right: 0;
    top: 100%;
    width: min(380px, calc(100vw - 2rem));
    z-index: 20;
  }

  .meta {
    color: var(--text-muted);
    font-size: 0.7rem;
    margin: 0 0 0.7rem;
  }

  ul {
    display: grid;
    gap: 0;
    list-style: none;
    margin: 0;
    padding: 0;
  }

  .row {
    align-items: center;
    display: flex;
    justify-content: space-between;
  }

  .panel > ul > li {
    border-top: 1px solid var(--border);
    padding: 0.65rem 0;
  }

  .panel > ul > li:last-child {
    padding-bottom: 0;
  }

  .source {
    color: var(--text-soft);
    font-size: 0.8rem;
    font-weight: 650;
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
    color: var(--warning);
  }

  .error .badge {
    color: var(--danger);
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

  @keyframes spin {
    to {
      transform: rotate(360deg);
    }
  }

  @media (max-width: 540px) {
    .status-toggle {
      font-size: 0;
      gap: 0;
      padding: 0.55rem;
    }
  }
</style>
