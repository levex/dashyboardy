<script lang="ts">
  import { onMount } from 'svelte'
  import { authApi, webAuthnSupported, type User } from './webauthn'

  let { onSuccess } = $props<{
    onSuccess: (user: User, backupCodes?: string[]) => void
  }>()

  let enrolled = $state(false)
  let loading = $state(true)
  let busy = $state(false)
  let error = $state<string | null>(null)
  let backupCode = $state('')
  let showBackup = $state(false)
  let backupCodes = $state<string[] | null>(null)

  onMount(() => {
    authApi
      .status()
      .then((status) => {
        enrolled = status.enrolled
        if (status.authenticated && status.user) {
          onSuccess(status.user)
        }
      })
      .catch(() => {
        error = 'Could not reach the server'
      })
      .finally(() => {
        loading = false
      })
  })

  async function enroll() {
    busy = true
    error = null
    try {
      const result = await authApi.register()
      backupCodes = result.backup_codes
      onSuccess(result.user, result.backup_codes)
    } catch (err) {
      error = err instanceof Error ? err.message : 'Enrollment failed'
    } finally {
      busy = false
    }
  }

  async function signIn() {
    busy = true
    error = null
    try {
      const result = await authApi.login()
      onSuccess(result.user)
    } catch (err) {
      error = err instanceof Error ? err.message : 'Sign in failed'
    } finally {
      busy = false
    }
  }

  async function signInWithBackup() {
    busy = true
    error = null
    try {
      const result = await authApi.backupLogin(backupCode)
      onSuccess(result.user)
    } catch (err) {
      error = err instanceof Error ? err.message : 'Invalid backup code'
    } finally {
      busy = false
    }
  }
</script>

{#if loading}
  <div class="center">Loading…</div>
{:else if backupCodes}
  <div class="card">
    <span class="lock-mark" aria-hidden="true">✓</span>
    <p class="eyebrow">Security setup</p>
    <h2>Save your backup codes</h2>
    <p class="hint">Store these somewhere safe. Each code works once if you lose your passkey.</p>
    <ul class="codes">
      {#each backupCodes as code (code)}
        <li><code>{code}</code></li>
      {/each}
    </ul>
    <button class="button" onclick={() => (backupCodes = null)}>I've saved them</button>
  </div>
{:else}
  <div class="card">
    <span class="lock-mark" aria-hidden="true">◆</span>
    <p class="eyebrow">Private dashboard</p>
    <h2>{enrolled ? 'Sign in' : 'Set up your dashboard'}</h2>

    {#if !webAuthnSupported()}
      <p class="error">Your browser does not support passkeys.</p>
    {:else if !enrolled}
      <p>Enroll a passkey to secure your personal dashboard. No password or Google account needed.</p>
      <button class="button" disabled={busy} onclick={enroll}>
        {busy ? 'Waiting for passkey…' : 'Enroll passkey'}
      </button>
    {:else}
      <p>Use your passkey to unlock the dashboard.</p>
      <button class="button" disabled={busy} onclick={signIn}>
        {busy ? 'Waiting for passkey…' : 'Sign in with passkey'}
      </button>
      <button class="link" onclick={() => (showBackup = !showBackup)}>
        {showBackup ? 'Hide backup code login' : 'Use a backup code'}
      </button>

      {#if showBackup}
        <form
          class="backup-form"
          onsubmit={(event) => {
            event.preventDefault()
            signInWithBackup()
          }}
        >
          <input
            bind:value={backupCode}
            placeholder="xxxx-xxxx"
            autocomplete="one-time-code"
            aria-label="Backup code"
          />
          <button class="button secondary" disabled={busy || !backupCode}>Sign in</button>
        </form>
      {/if}
    {/if}

    {#if error}
      <p class="error">{error}</p>
    {/if}
  </div>
{/if}

<style>
  .center {
    color: var(--text-muted);
    min-height: 40vh;
    place-content: center;
    text-align: center;
  }

  .card {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    box-shadow: var(--shadow);
    display: grid;
    gap: 0.9rem;
    margin: min(14vh, 7rem) auto 0;
    max-width: 460px;
    padding: clamp(1.5rem, 5vw, 2.5rem);
    text-align: center;
  }

  .lock-mark {
    align-items: center;
    background: var(--accent-soft);
    border: 1px solid rgba(143, 168, 255, 0.25);
    border-radius: 12px;
    color: var(--accent);
    display: flex;
    font-size: 0.8rem;
    height: 42px;
    justify-content: center;
    margin: 0 auto 0.25rem;
    width: 42px;
  }

  .eyebrow {
    color: var(--text-muted);
    font-size: 0.66rem;
    font-weight: 650;
    letter-spacing: 0.11em;
    text-transform: uppercase;
  }

  h2 {
    color: var(--text);
    font-size: 1.45rem;
    letter-spacing: -0.035em;
    margin: 0;
  }

  p {
    color: var(--text-muted);
    margin: 0;
  }

  .hint {
    font-size: 0.9rem;
  }

  .button {
    background: var(--accent);
    border: 1px solid var(--accent);
    border-radius: 7px;
    color: #10131d;
    cursor: pointer;
    font-weight: 700;
    padding: 0.7rem 1rem;
  }

  .button:hover:not(:disabled) {
    background: var(--accent-hover);
    border-color: var(--accent-hover);
  }

  .button.secondary {
    background: transparent;
    border: 1px solid var(--border);
    color: var(--text);
  }

  .button:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }

  .link {
    background: none;
    border: none;
    color: var(--accent);
    cursor: pointer;
    font-size: 0.85rem;
  }

  .backup-form {
    display: grid;
    gap: 0.5rem;
  }

  input {
    background: var(--bg);
    border: 1px solid var(--border);
    border-radius: 7px;
    color: var(--text);
    padding: 0.6rem 0.75rem;
  }

  .codes {
    display: grid;
    gap: 0.35rem;
    list-style: none;
    margin: 0;
    padding: 0;
    text-align: left;
  }

  code {
    font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
    font-size: 0.95rem;
  }

  .error {
    color: var(--danger);
  }
</style>
