defmodule ProcessingLibrary.QueueWorker do
  use GenServer
  require Logger

  def init(_init_arg) do
    {:ok, pubsub_conn} = Redix.PubSub.start_link()
    {:ok, queues} = ProcessingLibrary.Redis.get_queues()

    subscribe_to_queues(pubsub_conn, queues)
    start_processing(queues)

    {:ok, %{pubsub_conn: pubsub_conn}}
  end

  def start_link(_init_arg) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def subscribe_to_queues(conn, patterns) do
    Enum.each(patterns, fn pattern ->
      Redix.PubSub.subscribe(conn, pattern, self())
    end)
  end

  def start_processing(queues) do
    Enum.each(queues, fn queue ->
      namespace = ProcessingLibrary.Env.get_redis_namespace()
      ^namespace <> ":" <> queue = queue
      ProcessingLibrary.Job.publish_last_job(queue)
    end)
  end

  def handle_info({:redix_pubsub, _pubsub_conn, _ref, :message, %{payload: payload}}, state) do
    ProcessingLibrary.Job.process_job(payload)
    {:noreply, state}
  end

  def handle_info({:redix_pubsub, _pubsub_conn, _ref, :subscribed, %{channel: channel}}, state) do
    Logger.info("Redis pub/sub successfuly subscribed to #{channel} channel")
    {:noreply, state}
  end
end
