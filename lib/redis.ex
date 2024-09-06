defmodule ProcessingLibrary.Redis do
  use GenServer

  @namespace ProcessingLibrary.get_namespace()

  def start_link(_init_arg) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_init_arg) do
    {:ok, conn} = Redix.start_link("redis://localhost:6379")
    {:ok, conn}
  end

  defp queue_with_namespace(queue) do
    "#{@namespace}:#{queue}"
  end

  defp channel_with_namespace(queue) do
    "#{@namespace}:#{queue}"
  end

  def keys_with_namespace() do
    GenServer.call(__MODULE__, :keys_with_namespace)
  end

  def queue(queue, value) do
    GenServer.call(__MODULE__, {:queue, queue_with_namespace(queue), value})
  end

  def dequeue(queue) do
    GenServer.call(__MODULE__, {:dequeue, queue_with_namespace(queue)})
  end

  def publish(channel, job) do
    GenServer.call(__MODULE__, {:publish, channel_with_namespace(channel), job})
  end

  def get_last_in_queue(queue) do
    GenServer.call(__MODULE__, {:get_last_in_queue, queue_with_namespace(queue)})
  end

  def get_queue(queue) do
    GenServer.call(__MODULE__, {:get_queue, queue_with_namespace(queue)})
  end

  def filter_keys(conn, keys, type) do
    Enum.filter(keys, fn key ->
      Redix.command!(conn, ["TYPE", key]) == type
    end)
  end

  def filter_queues(conn, keys) do
    filter_keys(conn, keys, "queues")
  end

  def handle_call({:queue, queue, value}, _from, conn) do
    response = Redix.command(conn, ["LPUSH", queue, value])
    {:reply, response, conn}
  end

  def handle_call({:dequeue, queue}, _from, conn) do
    response = Redix.command(conn, ["RPOP", queue])
    {:reply, response, conn}
  end

  def handle_call({:get_queue, queue}, _from, conn) do
    response = Redix.command(conn, ["LRANGE", queue, "0", "-1"])
    {:reply, response, conn}
  end

  def handle_call({:publish, channel, job}, _from, conn) do
    response = Redix.command(conn, ["PUBLISH", channel, job])
    {:reply, response, conn}
  end

  def handle_call({:get_last_in_queue, queue}, _from, conn) do
    response = Redix.command(conn, ["LRANGE", queue, "-1", "-1"])
    {:reply, response, conn}
  end

  def handle_call(:keys_with_namespace, _from, conn) do
    response = Redix.command(conn, ["KEYS", "#{@namespace}:*"])
    {:reply, response, conn}
  end
end
