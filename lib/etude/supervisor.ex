defmodule Etude.Supervisor do
  @moduledoc """
  Top level supervisor
  """

  @vnode_spec %{
    id: Etude.VNode_master,
    start: {:riak_core_vnode_master, :start_link, [Etude.VNode]},
    restart: :permanent,
    shutdown: 5000,
    type: :worker,
    modules: [:riak_core_vnode_master]
  }

  @write_sup_spec %{
    id: Etude.Stat.WriteFSMSup,
    start: {Etude.Stat.WriteFSMSup, :start_link, []},
    restart: :permanent,
    timeout: :infinity,
    type: :supervisor,
    modules: [Etude.Stat.WriteFSMSup]
  }

  @read_sup_spec %{
    id: Etude.Stat.ReadFSMSup,
    start: {Etude.Stat.ReadFSMSup, :start_link, []},
    restart: :permanent,
    timeout: :infinity,
    type: :supervisor,
    modules: [Etude.Stat.ReadFSMSup]
  }

  @sup_flags [
    strategy: :one_for_one,
    max_restarts: 5,
    max_seconds: 10
  ]

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    children = [
      @vnode_spec,
      @write_sup_spec,
      @read_sup_spec
    ]

    Supervisor.init(children, @sup_flags)
  end
end
