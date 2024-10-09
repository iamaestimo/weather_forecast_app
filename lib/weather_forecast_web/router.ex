defmodule WeatherForecastWeb.Router do
  use WeatherForecastWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {WeatherForecastWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", WeatherForecastWeb do
    pipe_through :browser

    get "/", WeatherController, :index
    get "/forecast", WeatherController, :forecast
  end

  # Other scopes may use custom stacks.
  # scope "/api", WeatherForecastWeb do
  #   pipe_through :api
  # end
end
