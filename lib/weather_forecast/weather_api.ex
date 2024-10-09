defmodule WeatherForecast.WeatherApi do
  use Tesla

  plug Tesla.Middleware.Telemetry
  plug Tesla.Middleware.BaseUrl, "http://api.weatherapi.com/v1"
  plug Tesla.Middleware.JSON


  def client do
    api_key = System.get_env("WEATHER_API_KEY")
    middleware = [
      {Tesla.Middleware.Query, [key: api_key]},
      Tesla.Middleware.Logger  # Add this to see detailed logs of the requests
    ]
    Tesla.client(middleware)
  end

  def get_forecast(city) do
    Appsignal.instrument("api.weather", "WeatherAPI Forecast for #{city}", fn ->
      client()
      |> get("/forecast.json", query: [q: city, days: 3])
      |> case do
        {:ok, %{status: 200, body: body}} -> {:ok, parse_forecast(body)}
        {:ok, %{status: status, body: body}} ->
          IO.inspect(body, label: "API Error Response")
          {:error, "API request failed with status #{status}"}
        {:error, error} -> {:error, error}
      end
    end)
  end

  defp parse_forecast(body) do
    body["forecast"]["forecastday"]
    |> Enum.map(fn day ->
      %{
        date: day["date"],
        max_temp: day["day"]["maxtemp_c"],
        min_temp: day["day"]["mintemp_c"],
        condition: day["day"]["condition"]["text"]
      }
    end)
  end
end
