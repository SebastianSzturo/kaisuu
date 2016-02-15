defmodule Kaisuu.RedisPool do
  use Supervisor

  IO.puts "ENV: #{System.get_env("MIX_ENV")}"
  if System.get_env("MIX_ENV") == "prod" do
    @redis_connection_params System.get_env("REDIS_URL")
  else
    @redis_connection_params "redis://localhost"
  end

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    pool_opts = [
      name: {:local, :redix_poolboy},
      worker_module: Redix,
      size: 10,
      max_overflow: 5,
    ]

    children = [
      :poolboy.child_spec(:redix_poolboy, pool_opts, @redis_connection_params)
    ]

    supervise(children, strategy: :one_for_one, name: __MODULE__)
  end

  def command(command) do
    :poolboy.transaction(:redix_poolboy, &Redix.command(&1, command))
  end

  def pipeline(commands) do
    :poolboy.transaction(:redix_poolboy, &Redix.pipeline(&1, commands))
  end
end
