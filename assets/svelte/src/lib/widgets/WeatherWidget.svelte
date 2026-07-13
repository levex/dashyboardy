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
        <div class="conditions truncate">{reading.conditions}</div>
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
    height: 100%;
    place-content: center;
  }

  .city h3 {
    font-size: 0.85rem;
    font-weight: 600;
    margin: 0 0 0.15rem;
  }

  .temp {
    font-size: clamp(1.25rem, 3vw, 1.75rem);
    font-weight: 700;
    line-height: 1.1;
  }

  .conditions {
    color: var(--text);
    font-size: 0.85rem;
    margin-top: 0.1rem;
  }

  .meta {
    color: var(--text-muted);
    font-size: 0.72rem;
    margin-top: 0.2rem;
  }
</style>
