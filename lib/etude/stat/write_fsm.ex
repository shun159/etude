defmodule Etude.Stat.WriteFSM do
  @moduledoc """
  The coordinator for stat write operations.
  This example will show how to properly replicate data in riak_core by making use
  of the _preflist_.
  """

  alias :gen_statem, as: GenStatem
  alias Etude.Stat.WriteFSMSup
  alias Etude.Stat.Utils

  @behaviour GenStatem

  defmodule Data do
    @moduledoc false

    defstruct req_id: 0,
              from: nil,
              client: nil,
              stat_name: nil,
              op: nil,
              value: :undefined,
              preflist: [],
              num_write: 0

    def new([req_id, from, client, stat_name, op, value]) do
      %Data{
        req_id: req_id,
        from: from,
        client: client,
        stat_name: stat_name,
        value: value,
        op: op
      }
    end
  end

  # API functions

  def write(client, stat_name, op),
    do: write(client, stat_name, op, :undefind)

  def write(client, stat_name, op, value) do
    req_id = Utils.make_reqid()

    start_args = [
      req_id,
      self(),
      client,
      stat_name,
      op,
      value
    ]

    WriteFSMSup.start_writer(start_args)
  end

  # gen_statem callback functions

  @n 3
  @w 2

  def callback_mode, do: :state_functions

  def start_link(req_id, from, client, stat_name, op),
    do: start_link(req_id, from, client, stat_name, op, :undefined)

  def start_link(req_id, from, client, stat_name, op, value),
    do: GenStatem.start_link(__MODULE__, [req_id, from, client, stat_name, op, value], [])

  def init(init_args) do
    data = Data.new(init_args)
    {:ok, :prepare, data, [{:next_event, :internal, :do}]}
  end

  def prepare(:internal, :do, %Data{client: client, stat_name: stat_name} = data0) do
    doc_idx = Utils.make_chash_key(client, stat_name)
    preflist = :riak_core_apl.get_apl(doc_idx, @n, :etude_stat)
    data = %{data0 | preflist: preflist}
    {:next_state, :execute, data, [{:next_event, :internal, :do}]}
  end

  def execute(:internal, :do, %Data{} = data0) do
    _ =
      do_execute(
        data0.preflist,
        data0.req_id,
        data0.stat_name,
        data0.op,
        data0.value
      )

    {:next_state, :wating, data0}
  end

  def wating(:info, {:ok, req_id}, %Data{} = data0),
    do: handle_reply_from_vnode(req_id, %{data0 | num_write: data0.num_w + 1})

  # private functions

  @spec do_execute(
          preflist :: :riak_core_apl.preflist2(),
          req_id :: pos_integer(),
          stat_name :: charlist(),
          op :: atom(),
          value :: :undefined | term()
        ) :: term()
  defp do_execute(preflist, req_id, stat_name, op, :undefined),
    do: apply(Etude.Stat.Vnode, op, [preflist, req_id, stat_name])

  defp do_execute(preflist, req_id, stat_name, op, value),
    do: apply(Etude.Stat.Vnode, op, [preflist, req_id, stat_name, value])

  defp handle_reply_from_vnode(req_id, %Data{num_write: num_write} = data)
       when num_write == @w do
    :ok = Process.send(data.from, {req_id, :ok}, [])
    {:stop, :normal, data}
  end

  defp handle_reply_from_vnode(_, data), do: {:keep_state, data}
end
