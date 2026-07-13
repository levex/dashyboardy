<script lang="ts">
  import { api, relativeTime, type WeatherReading } from '../api'

  let { refreshToken = 0 } = $props<{ refreshToken?: number }>()

  const readings = $derived.by(async (): Promise<WeatherReading[]> => {
    refreshToken
    try {
      return (await api.weather()).readings
    } catch {
      return []
    }
  })
</script>

<div class="grid">
  {#await readings then loadedReadings}
    {#each loadedReadings as reading (reading.city)}
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
  {/await}
</div>

<style>
  .grid {
    display: grid;
    gap: 0.6rem;
    grid-template-columns: repeat(auto-fit, minmax(110px, 1fr));
    height: 100%;
    place-content: stretch;
  }

  .city {
    background: var(--surface-raised);
    border: 1px solid var(--border);
    border-radius: 10px;
    min-width: 0;
    padding: 0.75rem;
  }

  .city h3 {
    color: var(--text-muted);
    font-size: 0.68rem;
    font-weight: 650;
    letter-spacing: 0.06em;
    margin: 0 0 0.45rem;
    text-transform: uppercase;
  }

  .temp {
    font-size: clamp(1.5rem, 3vw, 2.15rem);
    font-weight: 560;
    letter-spacing: -0.045em;
    line-height: 1;
  }

  .conditions {
    color: var(--text-soft);
    font-size: 0.78rem;
    margin-top: 0.35rem;
  }

  .meta {
    color: var(--text-muted);
    font-size: 0.72rem;
    margin-top: 0.2rem;
  }
</style>
