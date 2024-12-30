defmodule JokerCynic.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      JokerCynicWeb.Telemetry,
      JokerCynic.Repo,
      {DNSCluster, query: Application.get_env(:joker_cynic, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: JokerCynic.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: JokerCynic.Finch},
      # Telegram
      ExGram,
      {JokerCynicBot.Dispatcher, [method: :polling, token: JokerCynicBot.Token.value()]},
      # Start a worker by calling: JokerCynic.Worker.start_link(arg)
      # {JokerCynic.Worker, arg},
      # Start to serve requests, typically the last entry
      JokerCynicWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: JokerCynic.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl Application
  def config_change(changed, _new, removed) do
    JokerCynicWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
