defmodule Etude.Stat.Utils do
  @moduledoc false

  @spec make_reqid() :: non_neg_integer()
  def make_reqid, do: :erlang.phash2(:os.timestamp())

  @spec make_chash_key(charlist(), charlist()) :: binary()
  def make_chash_key(client, stat_name) do
    bkey = {client, stat_name}
    :riak_core_util.chash_key(bkey)
  end
end
