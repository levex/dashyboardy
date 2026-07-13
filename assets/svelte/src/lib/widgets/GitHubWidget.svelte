<script lang="ts">
  import { api, relativeTime, type GitHubCommit } from '../api'

  let { refreshToken = 0 } = $props<{ refreshToken?: number }>()

  let commits = $state<GitHubCommit[]>([])

  async function load() {
    try {
      const data = await api.github()
      commits = data.commits
    } catch {
      commits = []
    }
  }

  $effect(() => {
    refreshToken
    load()
  })
</script>

<ul class="list">
  {#each commits as commit (commit.id)}
    <li>
      <div class="row">
        <span class="repo">{commit.repo.split('/').pop()}</span>
        <span class="time">{relativeTime(commit.committed_at)}</span>
      </div>
      <a class="message" href={`https://github.com/${commit.repo}/commit/${commit.sha}`} target="_blank" rel="noreferrer">
        {commit.message}
      </a>
      <div class="author">{commit.author ?? 'unknown'} · {commit.sha}</div>
    </li>
  {:else}
    <li class="empty">No commits loaded yet</li>
  {/each}
</ul>

<style>
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
    gap: 0.5rem;
  }

  .repo {
    color: var(--accent);
    font-size: 0.8rem;
    font-weight: 600;
  }

  .time {
    color: var(--text-muted);
    font-size: 0.75rem;
    white-space: nowrap;
  }

  .message {
    color: var(--text);
    display: block;
    font-size: 0.9rem;
    margin-top: 0.2rem;
    text-decoration: none;
  }

  .message:hover {
    color: var(--accent);
  }

  .author {
    color: var(--text-muted);
    font-size: 0.75rem;
    margin-top: 0.15rem;
  }

  .empty {
    color: var(--text-muted);
  }
</style>
