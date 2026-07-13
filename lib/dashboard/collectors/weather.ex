defmodule Dashboard.Collectors.Weather do
  @moduledoc """
  Fetches weather for configured Hungarian cities via Open-Meteo.
  """

  require Logger
  alias Dashboard.Weather

  @api "https://api.open-meteo.com/v1/forecast"

  @coordinates %{
    "Budapest" => %{lat: 47.4979, lon: 19.0402},
    "Szeged" => %{lat: 46.2530, lon: 20.1414}
  }

  @weather_codes %{
    0 => "Clear",
    1 => "Mainly clear",
    2 => "Partly cloudy",
    3 => "Overcast",
    45 => "Fog",
    48 => "Depositing rime fog",
    51 => "Light drizzle",
    53 => "Drizzle",
    55 => "Dense drizzle",
    61 => "Slight rain",
    63 => "Rain",
    65 => "Heavy rain",
    71 => "Slight snow",
    73 => "Snow",
    75 => "Heavy snow",
    80 => "Rain showers",
    95 => "Thunderstorm"
  }

  def name(_opts \\ []), do: "weather"

  def collect(_opts \\ []) do
    now = DateTime.utc_now(:second)

    results =
      Enum.map(Weather.cities(), fn city ->
        fetch_city(city, now)
      end)

    {:ok, results}
  end

  defp fetch_city(city, recorded_at) do
    %{lat: lat, lon: lon} = Map.fetch!(@coordinates, city)
    url = "#{@api}?latitude=#{lat}&longitude=#{lon}&current=temperature_2m,relative_humidity_2m,weather_code"

    case Req.get(url) do
      {:ok, %{status: 200, body: %{"current" => current}}} ->
        code = current["weather_code"]
        conditions = Map.get(@weather_codes, code, "Unknown")

        Weather.insert_reading(%{
          city: city,
          temperature: current["temperature_2m"],
          humidity: current["relative_humidity_2m"],
          conditions: conditions,
          recorded_at: recorded_at,
          metadata: %{"weather_code" => code}
        })

        {:ok, city}

      {:ok, %{status: status, body: body}} ->
        Logger.warning("Weather collector failed for #{city}: HTTP #{status}")
        {:error, city, {status, body}}

      {:error, reason} ->
        Logger.warning("Weather collector failed for #{city}: #{inspect(reason)}")
        {:error, city, reason}
    end
  end
end
