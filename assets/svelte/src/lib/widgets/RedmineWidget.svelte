<script lang="ts">
  import { api, relativeTime, type RedmineIssue } from '../api'

  let { refreshToken = 0 } = $props<{ refreshToken?: number }>()

  let showAssigned = $state(false)

  const issues = $derived.by(async (): Promise<RedmineIssue[]> => {
    refreshToken
    showAssigned
    try {
      return (await api.redmine(showAssigned)).issues
    } catch {
      return []
    }
  })
</script>

<div class="widget-toolbar">
  <button class="chip" class:active={!showAssigned} onclick={() => (showAssigned = false)}>Recent</button>
  <button class="chip" class:active={showAssigned} onclick={() => (showAssigned = true)}>Mine</button>
</div>

<ul class="widget-list">
  {#await issues then loadedIssues}
    {#each loadedIssues as issue (issue.id)}
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
    display: flex;
    justify-content: space-between;
    gap: 0.5rem;
  }

  .id {
    color: var(--accent);
    font-size: 0.7rem;
    font-weight: 650;
  }

  .time {
    color: var(--text-muted);
    flex-shrink: 0;
    font-size: 0.72rem;
  }

  .title {
    color: var(--text-soft);
    font-size: 0.82rem;
    line-height: 1.45;
    margin-top: 0.3rem;
  }

  .meta {
    color: var(--text-muted);
    font-size: 0.68rem;
    margin-top: 0.25rem;
  }
</style>
