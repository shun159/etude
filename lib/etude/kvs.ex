defmodule Etude.KVS do
  @moduledoc """
  Mnesia Interface
  """

  require Record

  Record.defrecord(:test, key: 1, value: 2)

  @spec put(term(), term()) :: true
  def put(key, value) do
    entry = test(key: key, value: value)
    true = :ets.insert(:test, entry)
  end

  @spec get(term()) :: term()
  def get(key) do
    case :ets.lookup(:test, key) do
      [] ->
        nil

      [test(value: value) | _] ->
        value
    end
  end

  @spec delete(term()) :: true
  def delete(key) do
    true = :ets.delete(:test, key)
  end

  @spec is_empty?() :: boolean()
  def is_empty? do
    :ets.info(:test, :size) == 0
  end

  @spec create_table() :: :test
  def create_table do
    :ets.new(:test, [
      :public,
      :named_table,
      :set,
      {:keypos, test(:key) + 1},
      {:write_concurrency, true},
      {:read_concurrency, true}
    ])
  end
end
