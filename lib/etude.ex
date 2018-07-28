defmodule Etude do
  @moduledoc false

  def ping, do: ping(:os.timestamp())

  def put(key, value), do: sync_command(key, {:put, key, value})

  def get(key), do: sync_command(key, {:get, key})

  def delete(key), do: sync_command(key, {:delete, key})

  # private functions

  @typep idx :: [{non_neg_integer(), Node.t()}]
  @typep key :: {integer(), integer(), integer()}
  @typep cmd :: :ping

  @spec ping(key()) :: [pong: non_neg_integer()]
  def ping(key), do: sync_command(key, :ping)

  @spec hash_key(key()) :: binary()
  defp hash_key(key) do
    key
    |> make_bkey()
    |> :riak_core_util.chash_key()
  end

  @spec sync_command(key(), cmd()) :: result :: [term()]
  defp sync_command(key, command) do
    key
    |> get_apl()
    |> Enum.map(&sync_spawn_command(&1, command))
  end

  @spec get_apl(key()) :: idx()
  defp get_apl(key) do
    key
    |> hash_key()
    |> :riak_core_apl.get_apl(1, __MODULE__)
  end

  @spec sync_spawn_command(idx(), cmd()) :: result :: term()
  defp sync_spawn_command(index, command),
    do: :riak_core_vnode_master.sync_spawn_command(index, command, Etude.VNode_master)

  @spec make_bkey(key()) :: {__MODULE__, binary()}
  defp make_bkey(key), do: {__MODULE__, :erlang.term_to_binary(key)}
end
