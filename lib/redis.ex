defmodule ProcessingLibrary.Redis do
  use GenServer

  def start_link(_init_arg) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_init_arg) do
    {:ok, conn} = Redix.start_link("redis://localhost:6379")
    {:ok, conn}
  end

  def queue(queue, value) do
    GenServer.call(__MODULE__, {:queue, queue, value})
  end

  def dequeue(queue) do
    GenServer.call(__MODULE__, {:dequeue, queue})
  end

  def get_queue(queue) do
    GenServer.call(__MODULE__, {:get_queue, queue})
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
end
