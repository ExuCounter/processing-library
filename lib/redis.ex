defmodule ProcessingLibrary.Redis do
  use GenServer

  def start_link(_init_arg) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_init_arg) do
    {:ok, conn} =
      Redix.start_link(
        host: ProcessingLibrary.Env.get_redis_host(),
        port: ProcessingLibrary.Env.get_redis_port(),
        database: ProcessingLibrary.Env.get_redis_database()
      )

    {:ok, conn}
  end

  defp extract_key(key),
    do: key |> String.split(":", trim: true) |> List.last() |> String.to_atom()

  defp namespace_key(key) when is_atom(key), do: namespace_key(key |> Atom.to_string())

  defp namespace_key(key) do
    namespace = ProcessingLibrary.Env.get_redis_namespace()

    if String.contains?(key, namespace) do
      key
    else
      "#{namespace}:#{key}"
    end
  end

  def flush_db() do
    GenServer.call(__MODULE__, :flush_db)
  end

  def get_keys() do
    GenServer.call(__MODULE__, :keys)
  end

  def remove(queue, value) do
    GenServer.call(__MODULE__, {:remove, namespace_key(queue), value})
  end

  def enqueue(queue, value) do
    GenServer.call(__MODULE__, {:queue, namespace_key(queue), value})
  end

  def dequeue(queue) do
    GenServer.call(__MODULE__, {:dequeue, namespace_key(queue)})
  end

  def peek(queue, :rear) do
    GenServer.call(__MODULE__, {:peek, :rear, namespace_key(queue)})
  end

  def peek(queue, :front) do
    GenServer.call(__MODULE__, {:peek, :front, namespace_key(queue)})
  end

  def get_queue(queue) do
    GenServer.call(__MODULE__, {:get_queue, namespace_key(queue)})
  end

  def set(key, value) do
    GenServer.call(__MODULE__, {:set, namespace_key(key), value})
  end

  def get_queues() do
    GenServer.call(__MODULE__, :get_queues)
  end

  def filter_keys(conn, keys, type) do
    Enum.filter(keys, fn key ->
      Redix.command!(conn, ["TYPE", namespace_key(key)]) == type
    end)
  end

  def filter_out_stats_queues(queues) do
    Enum.filter(queues, fn queue ->
      not ProcessingLibrary.Stats.is_stats_queue?(queue)
    end)
  end

  def filter_queues(conn, keys) do
    queue_type = "list"
    filter_keys(conn, keys, queue_type) |> filter_out_stats_queues()
  end

  def handle_call({:queue, queue, value}, _from, conn) do
    response = Redix.command(conn, ~w(RPUSH #{queue} #{value}))
    {:reply, response, conn}
  end

  def handle_call({:dequeue, queue}, _from, conn) do
    response = Redix.command(conn, ~w(LPOP #{queue}))
    {:reply, response, conn}
  end

  def handle_call({:get_queue, queue}, _from, conn) do
    response = Redix.command(conn, ~w(LRANGE #{queue} 0 -1))
    {:reply, response, conn}
  end

  def handle_call({:peek, position, queue}, _from, conn) do
    index = if position == :front, do: 0, else: -1
    {:ok, range} = Redix.command(conn, ~w(LRANGE #{queue} #{index} #{index}))

    if range == [] do
      {:reply, {:ok, nil}, conn}
    else
      [last | _] = range
      {:reply, {:ok, last}, conn}
    end
  end

  def handle_call(:keys, _from, conn) do
    response = Redix.command(conn, ~w(KEYS #{namespace_key("*")}))
    {:reply, response, conn}
  end

  def handle_call(:get_queues, _from, conn) do
    with {:ok, keys} <- Redix.command(conn, ~w(KEYS #{namespace_key("*")})),
         keys <- Enum.map(keys, &extract_key/1),
         queues <- ProcessingLibrary.Redis.filter_queues(conn, keys) do
      {:reply, {:ok, queues}, conn}
    else
      error -> {:reply, {:error, error}, conn}
    end
  end

  def handle_call(:flush_db, _from, conn) do
    response = Redix.command(conn, ~w(FLUSHDB))
    {:reply, response, conn}
  end

  def handle_call({:set, key, value}, _from, conn) do
    response = Redix.command(conn, ~w(SET #{key} #{value}))
    {:reply, response, conn}
  end

  def handle_call({:remove, queue, value}, _from, conn) do
    {:ok, _count} = Redix.command(conn, ~w(LREM #{queue} 0 #{value}))
    {:reply, :ok, conn}
  end
end
