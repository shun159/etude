# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :riak_core,
  ring_state_dir: 'ring_data_dir',
  handoff_port: 8099,
  handoff_ip: '127.0.0.1',
  schema_dirs: ['priv']

config :sasl,
  errlog_type: :error

import_config "#{Mix.env()}.exs"

