defmodule WeatherForecast.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  @spec start(any(), any()) :: {:error, any()} | {:ok, pid()}
  def start(_type, _args) do
    api_key = System.get_env("WEATHER_API_KEY")
    if is_nil(api_key) do
      raise "WEATHER_API_KEY environment variable is not set!"
    end

    children = [
      WeatherForecastWeb.Telemetry,
      WeatherForecast.Repo,
      {DNSCluster, query: Application.get_env(:weather_forecast, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: WeatherForecast.PubSub},
      # Start a worker by calling: WeatherForecast.Worker.start_link(arg)
      # {WeatherForecast.Worker, arg},
      # Start to serve requests, typically the last entry
      WeatherForecastWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: WeatherForecast.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    WeatherForecastWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
