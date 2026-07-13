<script lang="ts">
  let { children, title, collapsed = false, onToggle } = $props<{
    children: import('svelte').Snippet
    title: string
    collapsed?: boolean
    onToggle?: () => void
  }>()
</script>

<section class={{ widget: true, collapsed }}>
  <header class="widget-header">
    <div class="widget-title">
      <span class="widget-indicator" aria-hidden="true"></span>
      <h2 class="truncate">{title}</h2>
    </div>
    {#if onToggle}
      <button
        class="toggle"
        onclick={onToggle}
        aria-label={`${collapsed ? 'Expand' : 'Collapse'} ${title} widget`}
        aria-expanded={!collapsed}
      >
        <span aria-hidden="true">{collapsed ? '⌄' : '⌃'}</span>
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
    box-shadow: var(--shadow);
    display: flex;
    flex-direction: column;
    height: 100%;
    min-height: 0;
    min-width: 0;
    overflow: hidden;
  }

  .widget-header {
    align-items: center;
    border-bottom: 1px solid var(--border);
    display: flex;
    flex-shrink: 0;
    gap: 0.5rem;
    justify-content: space-between;
    min-height: 45px;
    padding: 0.55rem 0.8rem 0.55rem 0.95rem;
  }

  .widget-title {
    align-items: center;
    display: flex;
    gap: 0.55rem;
    min-width: 0;
  }

  .widget-indicator {
    background: var(--accent);
    border-radius: 50%;
    height: 5px;
    opacity: 0.8;
    width: 5px;
  }

  .widget-header h2 {
    color: var(--text-soft);
    font-size: 0.75rem;
    font-weight: 650;
    letter-spacing: 0.035em;
    margin: 0;
    min-width: 0;
    text-transform: uppercase;
  }

  .toggle {
    background: transparent;
    border: 1px solid transparent;
    border-radius: 5px;
    color: var(--text-muted);
    cursor: pointer;
    flex-shrink: 0;
    font-size: 0.9rem;
    line-height: 1;
    padding: 0.2rem 0.4rem;
  }

  .toggle:hover {
    background: var(--surface-hover);
    border-color: var(--border);
    color: var(--text);
  }

  .widget-body {
    flex: 1;
    min-height: 0;
    min-width: 0;
    overflow: auto;
    overscroll-behavior: contain;
    padding: 0.9rem 1rem;
    scrollbar-color: var(--border-strong) transparent;
    scrollbar-width: thin;
  }

  .collapsed .widget-header {
    border-bottom: none;
  }

  .collapsed {
    height: auto;
    min-height: 45px;
  }

  @media (max-width: 720px) {
    .widget-body {
      padding: 0.85rem;
    }
  }
</style>
