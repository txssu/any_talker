defmodule AnyTalker.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children =
      [
        AnyTalker.PromEx,
        AnyTalkerWeb.Telemetry,
        AnyTalker.Repo,
        {DNSCluster, query: Application.get_env(:any_talker, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: AnyTalker.PubSub},
        AnyTalker.RateLimit,
        {Finch, name: AnyTalker.Finch},
        {AnyTalker.Cache, []},
        AnyTalkerWeb.Endpoint,
        {Oban, Application.fetch_env!(:any_talker, Oban)}
      ] ++ bot_children()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AnyTalker.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp bot_children do
    if Application.get_env(:any_talker, :start_bot) do
      [
        ExGram,
        {AnyTalkerBot.Dispatcher, [method: :polling, token: AnyTalkerBot.Config.bot_token()]}
      ]
    else
      []
    end
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl Application
  def config_change(changed, _new, removed) do
    AnyTalkerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
