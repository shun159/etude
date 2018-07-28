defmodule Etude.Supervisor do
  @moduledoc """
  Top level supervisor
  """

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    vnode_spec = {
      Etude.VNode,
      {:riak_core_vnode_master, :start_link, [Etude.VNode]},
      :permanent,
      5000,
      :worker,
      [:riak_core_vnode_master]
    }

    children = [vnode_spec]

    Supervisor.init(
      children,
      strategy: :one_for_all,
      max_restarts: 0,
      max_seconds: 1,
      name: __MODULE__
    )
  end
end
