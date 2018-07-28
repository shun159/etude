defmodule Etude.MixProject do
  use Mix.Project

  def project do
    [
      app: :etude,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: [compile: ["riak_core_schema", "compile"]]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :riak_core],
      mod: {Etude.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # riak_core dependencies
      {:riak_core, github: "Kyorai/riak_core", branch: "fifo-merge"},
      {:cuttlefish,
       github: "rabbitmq/cuttlefish", branch: "develop", manager: :rebar3, override: true},
      {:goldrush, github: "DeadZen/goldrush", tag: "0.1.9", manager: :rebar3, override: true},
      {:lager, github: "erlang-lager/lager", override: true},
    ]
  end
end
