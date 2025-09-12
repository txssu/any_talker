defmodule AnyTalker.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      AnyTalker.PromEx,
      AnyTalkerWeb.Telemetry,
      AnyTalker.Repo,
      {DNSCluster, query: Application.get_env(:any_talker, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: AnyTalker.PubSub},
      AnyTalker.RateLimit,
      # Start the Finch HTTP client for sending emails
      {Finch, name: AnyTalker.Finch},
      AnyTalker.NikitaPlayer,
      # Telegram
      {AnyTalker.Cache, []},
      ExGram,
      {AnyTalkerBot.Dispatcher, [method: :polling, token: AnyTalkerBot.Token.value()]},
      # Start a worker by calling: AnyTalker.Worker.start_link(arg)
      # {AnyTalker.Worker, arg},
      # Start to serve requests, typically the last entry
      AnyTalkerWeb.Endpoint,
      {Oban, Application.fetch_env!(:any_talker, Oban)}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AnyTalker.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl Application
  def config_change(changed, _new, removed) do
    AnyTalkerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
