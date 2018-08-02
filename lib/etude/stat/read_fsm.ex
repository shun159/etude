defmodule Etude.Stat.ReadFSM do
  @moduledoc """
  The coordinator for the stat get operations.
  The key here is to generate the preflist just like in write_fsm and then
  query each replica and wait until a quorum is met.
  """

  alias :gen_statem, as: GenStatem
  alias Etude.Stat.ReadFSMSup
  alias Etude.Stat.Utils

  @behaviour GenStatem

  defmodule Data do
    @moduledoc false

    defstruct req_id: 0,
              from: nil,
              client: nil,
              stat_name: nil,
              preflist: [],
              num_read: 0,
              replies: []

    def new([req_id, from, client, stat_name]) do
      %Data{
        req_id: req_id,
        from: from,
        client: client,
        stat_name: stat_name
      }
    end
  end

  # gen_statem callback functions

  @n 3
  @r 2

  def init(init_args) do
    data = Data.new(init_args)
    {:ok, :prepare, data, [{:next_event, :internal, :do}]}
  end

  def prepare(:internal, :do, %Data{} = data0) do
    doc_idx = Utils.make_chash_key(data0.client, data0.stat_name)
    preflist = :riak_core_apl.get_apl(doc_idx, @n, :etude_stat)
    data = %{data0 | preflist: preflist}
    {:next_state, :execute, data, [{:next_event, :internal, :do}]}
  end

  def execute(:internal, :do, %Data{} = data0) do
    Etude.Stat.VNode.get(data0.preflist, data0.req_id, data0.stat_name)
    {:next_state, :wating, data0}
  end
end
