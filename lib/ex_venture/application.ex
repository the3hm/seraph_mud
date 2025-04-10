defmodule ExVenture.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  @server Application.compile_env(:ex_venture, :networking, [])[:server]
  @cluster_size Application.compile_env(:ex_venture, :cluster, [])[:size]

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children =
      [
        cluster_supervisor(),
        {Squabble, [subscriptions: [Game.World.Master], size: @cluster_size]},
        supervisor(Data.Repo, []),
        supervisor(Web.Supervisor, []),
        supervisor(Game.Supervisor, []),
        listener()
      ]
      |> Enum.reject(&is_nil/1)

    Metrics.Setup.setup()

    opts = [strategy: :rest_for_one, name: ExVenture.Supervisor]

    report_errors = Application.compile_env(:ex_venture, :errors, [])[:report]

    if report_errors do
      {:ok, _} = Logger.add_backend(Sentry.LoggerBackend)
    end

    Supervisor.start_link(children, opts)
  end

  defp cluster_supervisor() do
    topologies = Application.compile_env(:libcluster, :topologies, nil)

    if topologies && Code.ensure_compiled?(Cluster.Supervisor) do
      {Cluster.Supervisor, [topologies, [name: ExVenture.ClusterSupervisor]]}
    end
  end

  defp listener() do
    case @server do
      true ->
        import Supervisor.Spec, warn: false
        worker(Networking.Listener, [])

      false ->
        nil
    end
  end
end
