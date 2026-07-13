<script lang="ts">
  import { api, relativeTime, type RedmineIssue } from '../api'

  let { refreshToken = 0 } = $props<{ refreshToken?: number }>()

  let issues = $state<RedmineIssue[]>([])
  let showAssigned = $state(false)

  async function load() {
    try {
      const data = await api.redmine(showAssigned)
      issues = data.issues
    } catch {
      issues = []
    }
  }

  $effect(() => {
    refreshToken
    showAssigned
    load()
  })
</script>

<div class="widget-toolbar">
  <button class="chip" class:active={!showAssigned} onclick={() => (showAssigned = false)}>Recent</button>
  <button class="chip" class:active={showAssigned} onclick={() => (showAssigned = true)}>Mine</button>
</div>

<ul class="widget-list">
  {#each issues as issue (issue.id)}
    <li class="item">
      <div class="row">
        <span class="id">#{issue.issue_id}</span>
        <span class="time">{relativeTime(issue.updated_at)}</span>
      </div>
      <div class="title line-clamp-2">{issue.title}</div>
      <div class="meta truncate">{issue.status} · {issue.assignee ?? 'unassigned'}</div>
    </li>
  {:else}
    <li class="widget-empty">No issues loaded yet</li>
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
    display: flex;
    justify-content: space-between;
    gap: 0.5rem;
  }

  .id {
    color: var(--accent);
    font-size: 0.75rem;
    font-weight: 600;
  }

  .time {
    color: var(--text-muted);
    flex-shrink: 0;
    font-size: 0.72rem;
  }

  .title {
    font-size: 0.85rem;
    margin-top: 0.2rem;
  }

  .meta {
    color: var(--text-muted);
    font-size: 0.72rem;
    margin-top: 0.15rem;
  }
</style>
