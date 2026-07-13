<script lang="ts">
  let { children, title, collapsed = false, onToggle } = $props<{
    children: import('svelte').Snippet
    title: string
    collapsed?: boolean
    onToggle?: () => void
  }>()
</script>

<section class="widget" class:collapsed>
  <header class="widget-header">
    <h2 class="truncate">{title}</h2>
    {#if onToggle}
      <button class="toggle" onclick={onToggle} aria-label="Toggle widget">
        {collapsed ? '+' : '−'}
      </button>
    {/if}
  </header>
  {#if !collapsed}
    <div class="widget-body">
      {@render children()}
    </div>
  {/if}
</section>

<style>
  .widget {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    display: flex;
    flex-direction: column;
    height: 100%;
    min-height: 0;
    min-width: 0;
    overflow: hidden;
  }

  .widget-header {
    align-items: center;
    background: var(--surface-raised);
    display: flex;
    flex-shrink: 0;
    gap: 0.5rem;
    justify-content: space-between;
    padding: 0.65rem 0.85rem;
  }

  .widget-header h2 {
    font-size: 0.88rem;
    font-weight: 600;
    letter-spacing: 0.01em;
    margin: 0;
    min-width: 0;
  }

  .toggle {
    background: transparent;
    border: 1px solid var(--border);
    border-radius: 6px;
    color: var(--text-muted);
    cursor: pointer;
    flex-shrink: 0;
    font-size: 0.95rem;
    line-height: 1;
    padding: 0.1rem 0.45rem;
  }

  .toggle:hover {
    border-color: var(--accent);
    color: var(--accent);
  }

  .widget-body {
    flex: 1;
    min-height: 0;
    min-width: 0;
    overflow: auto;
    overscroll-behavior: contain;
    padding: 0.65rem 0.85rem;
  }

  .collapsed .widget-header {
    border-bottom: none;
  }

  .collapsed {
    height: auto;
  }
</style>
