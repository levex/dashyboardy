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

<div class="toolbar">
  <button class:active={!showAssigned} onclick={() => (showAssigned = false)}>Recent</button>
  <button class:active={showAssigned} onclick={() => (showAssigned = true)}>Assigned to me</button>
</div>

<ul class="list">
  {#each issues as issue (issue.id)}
    <li>
      <div class="row">
        <span class="id">#{issue.issue_id}</span>
        <span class="time">{relativeTime(issue.updated_at)}</span>
      </div>
      <div class="title">{issue.title}</div>
      <div class="meta">{issue.status} · {issue.assignee ?? 'unassigned'}</div>
    </li>
  {:else}
    <li class="empty">No issues loaded yet</li>
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
    gap: 0.85rem;
    list-style: none;
    margin: 0;
    padding: 0;
  }

  .row {
    display: flex;
    justify-content: space-between;
  }

  .id {
    color: var(--accent);
    font-size: 0.8rem;
    font-weight: 600;
  }

  .time {
    color: var(--text-muted);
    font-size: 0.75rem;
  }

  .title {
    font-size: 0.9rem;
    margin-top: 0.2rem;
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
