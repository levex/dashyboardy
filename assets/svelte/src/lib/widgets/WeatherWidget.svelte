<script lang="ts">
  import { api, relativeTime, type WeatherReading } from '../api'

  let { refreshToken = 0 } = $props<{ refreshToken?: number }>()

  let readings = $state<WeatherReading[]>([])

  async function load() {
    try {
      const data = await api.weather()
      readings = data.readings
    } catch {
      readings = []
    }
  }

  $effect(() => {
    refreshToken
    load()
  })
</script>

<div class="grid">
  {#each readings as reading (reading.city)}
    <article class="city">
      <h3>{reading.city}</h3>
      {#if reading.temperature != null}
        <div class="temp">{Math.round(reading.temperature)}°C</div>
        <div class="conditions">{reading.conditions}</div>
        {#if reading.humidity != null}
          <div class="meta">{reading.humidity}% humidity</div>
        {/if}
        <div class="meta">{relativeTime(reading.recorded_at)}</div>
      {:else}
        <div class="meta">No data yet</div>
      {/if}
    </article>
  {/each}
</div>

<style>
  .grid {
    display: grid;
    gap: 0.75rem;
  }

  .city h3 {
    font-size: 0.95rem;
    margin: 0 0 0.25rem;
  }

  .temp {
    font-size: 1.75rem;
    font-weight: 700;
  }

  .conditions {
    color: var(--text);
    margin-top: 0.15rem;
  }

  .meta {
    color: var(--text-muted);
    font-size: 0.8rem;
    margin-top: 0.25rem;
  }
</style>
