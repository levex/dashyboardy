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
    gap: 0.25rem;
    height: 100%;
    place-content: center;
    text-align: center;
  }

  .time {
    font-size: clamp(1.5rem, 4vw, 2rem);
    font-variant-numeric: tabular-nums;
    font-weight: 700;
    line-height: 1.1;
  }

  .date {
    color: var(--text-muted);
    font-size: 0.8rem;
  }
</style>
