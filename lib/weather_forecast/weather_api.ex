defmodule WeatherForecast.WeatherApi do
  use Tesla

  plug Tesla.Middleware.Telemetry
  plug Tesla.Middleware.BaseUrl, "http://api.weatherapi.com/v1"
  plug Tesla.Middleware.JSON


  def client do
    api_key = System.get_env("WEATHER_API_KEY")
    middleware = [
      {Tesla.Middleware.Query, [key: api_key]},
      Tesla.Middleware.Logger
    ]
    Tesla.client(middleware)
  end

  # def get_forecast(city) do
  #   Appsignal.instrument("Weather API - Get Forecast", "WeatherAPI Forecast for #{city}", fn ->
  #     client()
  #     |> get("/forecast.json", query: [q: city, days: 3])
  #     |> case do
  #       {:ok, %{status: 200, body: body}} -> {:ok, parse_forecast(body)}
  #       {:ok, %{status: status, body: body}} ->
  #         IO.inspect(body, label: "API Error Response")
  #         {:error, "API request failed with status #{status}"}
  #       {:error, error} -> {:error, error}
  #     end
  #   end)
  # end

  def get_forecast(city) do
    Appsignal.instrument("Weather API - Get Forecast", fn span ->
      Appsignal.Span.set_sample_data(span, "params", %{city: city})

      client()
      |> get("/forecast.json", query: [q: city, days: 3])
      |> case do
        {:ok, %{status: 200, body: body}} ->
          {:ok, parse_forecast(body)}
        {:ok, %{status: status, body: body}} ->
          error_message = "API request failed with status #{status}"
          stacktrace = get_application_stacktrace()
          Appsignal.send_error(%RuntimeError{message: error_message},
                               stacktrace,
                               fn error_span ->
                                 Appsignal.Span.set_sample_data(error_span, "error", %{
                                   status: status,
                                   body: body,
                                   city: city
                                 })
                               end)
          {:error, error_message}
        {:error, %Tesla.Error{reason: reason} = error} ->
          error_message = "API request failed: #{inspect(reason)}"
          stacktrace = get_application_stacktrace()
          Appsignal.send_error(error,
                               stacktrace,
                               fn error_span ->
                                 Appsignal.Span.set_sample_data(error_span, "error", %{
                                   reason: reason,
                                   city: city
                                 })
                               end)
          {:error, error_message}
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


  defp get_application_stacktrace do
    {_, full_stacktrace} = Process.info(self(), :current_stacktrace)
    Enum.filter(full_stacktrace, fn {module, _function, _arity, _location} ->
      to_string(module) =~ "WeatherForecast"
    end)
  end

end
