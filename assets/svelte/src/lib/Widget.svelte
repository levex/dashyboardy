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
    <h2>{title}</h2>
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
    border-radius: 12px;
    display: flex;
    flex-direction: column;
    min-height: 0;
    overflow: hidden;
  }

  .widget-header {
    align-items: center;
    border-bottom: 1px solid var(--border);
    display: flex;
    justify-content: space-between;
    padding: 0.75rem 1rem;
  }

  .widget-header h2 {
    font-size: 0.95rem;
    font-weight: 600;
    margin: 0;
  }

  .toggle {
    background: transparent;
    border: 1px solid var(--border);
    border-radius: 6px;
    color: var(--text-muted);
    cursor: pointer;
    font-size: 1rem;
    line-height: 1;
    padding: 0.1rem 0.45rem;
  }

  .widget-body {
    flex: 1;
    min-height: 0;
    overflow: auto;
    padding: 0.75rem 1rem;
  }

  .collapsed .widget-header {
    border-bottom: none;
  }
</style>
