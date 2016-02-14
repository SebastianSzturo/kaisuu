defmodule Kaisuu.RedisRepo do
  def start_link(name) do
    client = Exredis.start_link
    true = Process.register(client, name)
    {:ok, client}
  end
end
