use Mix.Config

config :riak_core,
  node: 'node4@127.0.0.1',
  web_port: 8498,
  handoff_port: 8499,
  ring_state_dir: 'ring_data_dir_4',
  platform_data_dir: 'data_4'
