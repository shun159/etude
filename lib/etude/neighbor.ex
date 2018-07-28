defmodule Etude.Neighbor do
  @moduledoc """
  Ditributed riak_core_vnode process console
  """

  require Logger

  @spec join(Node.t()) :: :ok | :error
  def join(node_name) when is_atom(node_name) do
    join(
      ~c"#{node_name}",
      &:riak_core.staged_join/1,
      "Success: staged join request for #{Node.self()} to #{node_name}"
    )
  end

  @spec leave() :: :ok | {:error, reason :: term()}
  def leave do
    :riak_core.leave()
  end

  # private functions

  defp join(node_str, join_fn, success_msg) do
    case join_fn.(node_str) do
      :ok ->
        Logger.info(success_msg)
        :ok

      {:error, :not_reachable} ->
        Logger.warn("Node #{node_str} is not reachable !")
        :error

      {:error, :different_ring_size} ->
        Logger.warn("Failed: Node #{node_str} has different ring_creation_size")
        :error

      {:error, :unable_to_get_ring_join} ->
        Logger.warn("Failed: Unable to get ring from #{node_str}")
        :error

      {:error, :not_single_node} ->
        Logger.warn("Failed: This node is already member of a cluster")
        :error

      {:error, :self_join} ->
        Logger.warn("Failed: This join cannot join itself in a cluster")
        :error

      {:error, _} ->
        Logger.warn("Join failed. Try again in a few momemts")
        :error
    end
  catch
    exception, reason ->
      Logger.error("Join Failed exception: #{inspect(exception)} reason: #{inspect(reason)}")
      :error
  end
end
