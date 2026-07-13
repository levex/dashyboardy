<script lang="ts">
  import { api, relativeTime, type GitHubCommit } from '../api'

  let {
    refreshToken = 0,
    selectedRepo = 'all',
    onRepoChange
  } = $props<{
    refreshToken?: number
    selectedRepo?: string
    onRepoChange?: (repo: string) => void
  }>()

  function repoLabel(repo: string) {
    if (repo === 'all') return 'All repos'
    const short = repo.split('/').pop() ?? repo
    return short
  }

  const githubData = $derived.by(async (): Promise<{ commits: GitHubCommit[]; repos: string[] }> => {
    refreshToken
    selectedRepo
    try {
      return await api.github(selectedRepo === 'all' ? undefined : selectedRepo)
    } catch {
      return { commits: [], repos: [] }
    }
  })
</script>

{#await githubData then data}
  <div class="widget-toolbar">
    <select
      class="widget-select"
      value={selectedRepo}
      onchange={(e) => onRepoChange?.(e.currentTarget.value)}
      aria-label="GitHub repository"
    >
      <option value="all">All repositories</option>
      {#each data.repos as repo (repo)}
        <option value={repo}>{repo}</option>
      {/each}
    </select>
  </div>

  <ul class="widget-list">
    {#each data.commits as commit (commit.id)}
      <li class="commit">
        <div class="row">
          {#if selectedRepo === 'all'}
            <span class="repo truncate">{repoLabel(commit.repo)}</span>
          {/if}
          <span class="time">{relativeTime(commit.committed_at)}</span>
        </div>
        <a
          class="message line-clamp-2"
          href={`https://github.com/${commit.repo}/commit/${commit.sha}`}
          target="_blank"
          rel="noreferrer"
          title={commit.message}
        >
          {commit.message}
        </a>
        <div class="meta truncate">{commit.author ?? 'unknown'} · {commit.sha}</div>
      </li>
    {:else}
      <li class="widget-empty">No commits for this repository yet</li>
    {/each}
  </ul>
{/await}

<style>
  .commit {
    border-bottom: 1px solid var(--border);
  }

  .commit:last-child {
    border-bottom: none;
    padding-bottom: 0;
  }

  .row {
    align-items: center;
    display: flex;
    gap: 0.5rem;
    justify-content: space-between;
    min-width: 0;
  }

  .repo {
    color: var(--accent);
    font-size: 0.7rem;
    font-weight: 650;
    min-width: 0;
  }

  .time {
    color: var(--text-muted);
    flex-shrink: 0;
    font-size: 0.72rem;
  }

  .message {
    color: var(--text-soft);
    display: block;
    font-size: 0.82rem;
    line-height: 1.45;
    margin-top: 0.3rem;
    text-decoration: none;
  }

  .message:hover {
    color: var(--accent);
  }

  .meta {
    color: var(--text-muted);
    font-size: 0.68rem;
    margin-top: 0.25rem;
  }

  .widget-select {
    flex: 1;
    min-width: 0;
  }
</style>
