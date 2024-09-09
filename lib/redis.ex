defmodule ProcessingLibrary.Redis do
  use GenServer

  def start_link(_init_arg) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(), do: init(nil)

  def init(_init_arg) do
    {:ok, conn} =
      Redix.start_link(
        host: ProcessingLibrary.Env.get_redis_host(),
        port: ProcessingLibrary.Env.get_redis_port(),
        database: ProcessingLibrary.Env.get_redis_database()
      )

    {:ok, conn}
  end

  defp namespaced(key) do
    "#{ProcessingLibrary.Env.get_redis_namespace()}:#{key}"
  end

  def flush_db() do
    GenServer.call(__MODULE__, :flush_db)
  end

  def get_keys() do
    GenServer.call(__MODULE__, :keys)
  end

  def enqueue(queue, value) do
    GenServer.call(__MODULE__, {:queue, namespaced(queue), value})
  end

  def dequeue(queue) do
    GenServer.call(__MODULE__, {:dequeue, namespaced(queue)})
  end

  def publish(channel, job) do
    GenServer.call(__MODULE__, {:publish, namespaced(channel), job})
  end

  def get_last_in_queue(queue) do
    GenServer.call(__MODULE__, {:get_last_in_queue, namespaced(queue)})
  end

  def get_queue(queue) do
    GenServer.call(__MODULE__, {:get_queue, namespaced(queue)})
  end

  def get_queues() do
    GenServer.call(__MODULE__, :get_queues)
  end

  def set(key, value) do
    GenServer.call(__MODULE__, {:set, namespaced(key), value})
  end

  def filter_keys(conn, keys, type) do
    Enum.filter(keys, fn key ->
      Redix.command!(conn, ["TYPE", key]) == type
    end)
  end

  def filter_queues(conn, keys) do
    filter_keys(conn, keys, "list")
  end

  def handle_call({:queue, queue, value}, _from, conn) do
    response = Redix.command(conn, ~w(LPUSH #{queue} #{value}))
    {:reply, response, conn}
  end

  def handle_call({:dequeue, queue}, _from, conn) do
    response = Redix.command(conn, ~w(RPOP #{queue}))
    {:reply, response, conn}
  end

  def handle_call({:get_queue, queue}, _from, conn) do
    response = Redix.command(conn, ~w(LRANGE #{queue} 0 -1))
    {:reply, response, conn}
  end

  def handle_call({:publish, channel, job}, _from, conn) do
    response = Redix.command(conn, ~w(PUBLISH #{channel} #{job}))
    {:reply, response, conn}
  end

  def handle_call({:get_last_in_queue, queue}, _from, conn) do
    {:ok, last} = Redix.command(conn, ~w(LRANGE #{queue} -1 -1))

    if last == [] do
      {:reply, {:ok, nil}, conn}
    else
      {:reply, {:ok, last}, conn}
    end
  end

  def handle_call(:keys, _from, conn) do
    response = Redix.command(conn, ~w(KEYS #{ProcessingLibrary.Env.get_redis_namespace()}:*))
    {:reply, response, conn}
  end

  def handle_call(:get_queues, _from, conn) do
    {:ok, keys} =
      Redix.command(conn, ~w(KEYS #{ProcessingLibrary.Env.get_redis_namespace()}:*))

    queues = ProcessingLibrary.Redis.filter_queues(conn, keys)

    {:reply, {:ok, queues}, conn}
  end

  def handle_call(:flush_db, _from, conn) do
    response = Redix.command(conn, ~w(FLUSHDB))
    {:reply, response, conn}
  end

  def handle_call({:set, key, value}, _from, conn) do
    response = Redix.command(conn, ~w(SET #{key} #{value}))
    {:reply, response, conn}
  end
end
