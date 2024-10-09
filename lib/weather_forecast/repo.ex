defmodule WeatherForecast.Repo do
  use Ecto.Repo,
    otp_app: :weather_forecast,
    adapter: Ecto.Adapters.Postgres
end
