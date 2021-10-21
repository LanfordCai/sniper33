defmodule Sniper33.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Sniper33.Repo,
      # Start the Telemetry supervisor
      Sniper33Web.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Sniper33.PubSub},
      # Start the Endpoint (http/https)
      Sniper33Web.Endpoint,
      # Start a worker by calling: Sniper33.Worker.start_link(arg)
      # {Sniper33.Worker, arg}
      Sniper33
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Sniper33.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Sniper33Web.Endpoint.config_change(changed, removed)
    :ok
  end
end
