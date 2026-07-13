<script lang="ts">
  import { onMount } from 'svelte'

  let now = $state(new Date())

  onMount(() => {
    const interval = setInterval(() => {
      now = new Date()
    }, 1000)
    return () => clearInterval(interval)
  })

  const time = $derived(
    now.toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit', second: '2-digit' })
  )
  const date = $derived(
    now.toLocaleDateString('en-GB', { weekday: 'short', month: 'short', day: 'numeric' })
  )
</script>

<div class="clock">
  <div class="time">{time}</div>
  <div class="date">{date}</div>
</div>

<style>
  .clock {
    display: grid;
    gap: 0.4rem;
    height: 100%;
    place-content: center;
  }

  .time {
    font-size: clamp(2rem, 5vw, 3.15rem);
    font-variant-numeric: tabular-nums;
    font-weight: 560;
    letter-spacing: -0.055em;
    line-height: 1;
  }

  .date {
    color: var(--text-muted);
    font-size: 0.72rem;
    letter-spacing: 0.08em;
    text-transform: uppercase;
  }
</style>
