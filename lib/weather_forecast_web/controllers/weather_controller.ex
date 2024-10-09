defmodule WeatherForecastWeb.WeatherController do
  use WeatherForecastWeb, :controller
  alias WeatherForecast.WeatherApi

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def forecast(conn, %{"city" => city}) do
    case WeatherApi.get_forecast(city) do
      {:ok, forecast} ->
        render(conn, "forecast.html", forecast: forecast, city: city)
      {:error, reason} ->
        conn
        |> put_flash(:error, "Unable to fetch forecast: #{reason}")
        |> redirect(to: ~p"/")
    end
  end
end
