defmodule Mix.Tasks.RiakCoreSchema do
  use Mix.Task

  @riak_core_schema_path "deps/riak_core/priv"
  @dst_dir "priv"

  @shortdoc "copy a riak_core's schema file from deps/riak_core/priv"
  def run(_) do
    case File.mkdir(@dst_dir) do
      :ok ->
        {:ok, _} = File.cp_r(@riak_core_schema_path, @dst_dir)

      {:error, :eexist} ->
        {:ok, _} = File.cp_r(@riak_core_schema_path, @dst_dir)
    end
  end
end
