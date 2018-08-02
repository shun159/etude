defmodule Etude.Stat.WriteFSMSup do
  use Supervisor

  alias Etude.Stat.WriteFSM

  @write_fsm_spec %{
    id: :undefined,
    start: {WriteFSM, :start_link, []},
    restart: :temporary,
    shutdown: 5000,
    type: :worker,
    modules: [WriteFSM]
  }

  @sup_flags [
    strategy: :simple_one_for_one,
    max_restarts: 10,
    max_seconds: 10
  ]

  def start_writer(args) do
    Supervisor.start_child(__MODULE__, args)
  end

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    Supervisor.init([@write_fsm_spec], @sup_flags)
  end
end
