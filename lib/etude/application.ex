defmodule Etude.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    _ = Etude.KVS.create_table()

    :ok = :riak_core.register(vnode_module: Etude.VNode)
    :ok = :riak_core_node_watcher.service_up(Etude, self())

    Etude.Supervisor.start_link()
  end
end
