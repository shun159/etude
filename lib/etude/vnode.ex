defmodule Etude.VNode do
  @moduledoc """
  riak_core_vnode callback module
  """

  @behaviour :riak_core_vnode

  require Record
  require Logger

  @header "riak_core/include/riak_core_vnode.hrl"

  for {name, field} <- Record.extract_all(from_lib: @header) do
    Record.defrecord(name, field)
  end

  def start_vnode(index) do
    :riak_core_vnode_master.get_vnode_pid(index, __MODULE__)
  end

  def init([partition]) do
    :ok = Logger.debug("vnode started: partition = #{partition}")
    {:ok, partition}
  end

  def handle_command(:ping, _from, partition) do
    :ok = Logger.debug("Received ping command: p = #{partition}")
    {:reply, {:pong, partition}, partition}
  end

  def handle_command({:put, key, value}, _from, state) do
    :ok = Logger.debug("PUT: key: #{inspect(key)}, value: #{inspect(value)} p = #{state}")
    true = Etude.KVS.put(key, value)
    {:reply, :ok, state}
  end

  def handle_command({:get, key}, _from, state) do
    :ok = Logger.debug("GET: key: #{inspect(key)} p = #{state}")
    value = Etude.KVS.get(key)
    {:reply, value, state}
  end

  def handle_command({:delete, key}, _from, state) do
    :ok = Logger.debug("DEL: key: #{inspect(key)} p = #{state}")
    true = Etude.KVS.delete(key)
    {:reply, :ok, state}
  end

  def handle_handoff_command(command, from, state) do
    :ok = Logger.debug("handoff command: #{inspect(command)}")
    {:reply, _result, new_state} = handle_command(command, from, state)
    {:forward, new_state}
  end

  def handoff_starting(_target_node, state) do
    :ok = Logger.info("handoff starting")
    {true, state}
  end

  def handoff_cancelled(state) do
    :ok = Logger.info("handoff cancelled")
    {:ok, state}
  end

  def handoff_finished(_handoff_dest, state) do
    :ok = Logger.info("handoff finished")
    {:ok, state}
  end

  def encode_handoff_item(key, value) do
    :erlang.term_to_binary({key, value})
  end

  def handle_handoff_data(:binary, state) do
    {:reply, {:error, :bad_data}, state}
  end

  ## This commands are not executed inside the VNode, instead they are
  ## part of the vnode_proxy contract.
  ##
  ## The vnode_proxy will drop requests in an overload situation, when
  ## his happens one of the two handle_overload_* commands in the
  ## vnode module is called. This call happens **from the vnode proxy**
  ##
  ## These calls are wrapped in a catch() meaning that when they don't
  ## exist they will quietly fail. However the catch is hugely expensive
  ## leading to the sitaution that when there already is a overload
  ## the vnode proxy gets even worst overloaded.
  ##
  ## This is pretty bad since the proxy is supposed to protect against
  ## exactly this overload.
  ##
  ## So yea sorry, you're going to be forced to implement them, if nothing
  ## else just nop them out.
  ##
  ## BUT DO NOT call expensive functions from them there is a special hell
  ## for people doing that! (it's called overflowing message queue hell and is
  ## really nasty!)
  def handle_overload_command(_, _, _) do
    :ok
  end

  def handle_overload_info(_, _) do
    :ok
  end

  ## handle_exit/3 is an optional behaviour callback that can be implemented.
  ## It will be called in the case that a process that is linked to the vnode
  ## process dies and allows the module using the behaviour to take appropriate
  ## action. It is called by handle_info when it receives an {'EXIT', Pid, Reason}
  ## message and the function signature is: handle_exit(Pid, Reason, State).
  ##
  ## It should return a tuple indicating the next state for the fsm. For a list of
  ## valid return types see the documentation for the gen_fsm_compat handle_info callback.
  ##
  ## Here is what the spec for handle_exit/3 would look like:
  ## -spec handle_exit(pid(), atom(), term()) ->
  ##                          {noreply, term()} |
  ##                          {stop, term(), term()}
  def handle_exit(_pid, _reason, state) do
    {:noreply, state}
  end

  def is_empty(state) do
    {Etude.KVS.is_empty?(), state}
  end

  def delete(state) do
    {:ok, state}
  end

  def handle_coverage(command, _key_spaces, _from, state) do
    {:stop, {:bad_coverage, command}, state}
  end

  def terminate(_reason, _state) do
    :ok
  end
end
