defmodule ProcessingLibrary.QueueWorker do
  use GenServer
  require Logger

  def init(_init_arg) do
    {:ok, pubsub_conn} = ProcessingLibrary.PubSub.start_link()
    {:ok, queues} = ProcessingLibrary.Database.get_queues()

    subscribe_to_queues(pubsub_conn, queues)
    start_processing(queues)

    {:ok, %{pubsub_conn: pubsub_conn}}
  end

  def start_link(_init_arg) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def log_context(%ProcessingLibrary.Job{worker_module: worker_module, jid: jid}) do
    "#{worker_module}[#{jid}]"
  end

  def publish_last_job(queue_name) do
    {:ok, job_json} = ProcessingLibrary.Database.Queue.get_last(queue_name)

    if not is_nil(job_json) do
      ProcessingLibrary.PubSub.publish(queue_name, job_json)
    end
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

      publish_last_job(queue)
    end)
  end

  def handle_info(
        {:redix_pubsub, _pubsub_conn, _ref, :message, %{payload: payload, channel: queue}},
        state
      ) do
    process_job(queue, payload)
    {:noreply, state}
  end

  def handle_info({:redix_pubsub, _pubsub_conn, _ref, :subscribed, %{channel: channel}}, state) do
    Logger.info("Redis pub/sub successfuly subscribed to #{channel} channel")
    {:noreply, state}
  end

  def process_job(%ProcessingLibrary.Job{} = job, queue) do
    Logger.info("#{log_context(job)} start")

    try do
      start_time = DateTime.utc_now()
      apply(job.worker_module |> String.to_atom(), :perform, [job.params])
      finish_time = DateTime.utc_now()
      diff_time = DateTime.diff(finish_time, start_time, :millisecond)

      Logger.info("#{log_context(job)} )} finished in #{diff_time}ms")

      ProcessingLibrary.Enqueuer.enqueue(:processed, job)
    rescue
      _ ->
        Logger.error("#{log_context(job)})} failed with exception")
        ProcessingLibrary.Enqueuer.enqueue(:failed, job)
    end

    ProcessingLibrary.Dequeuer.dequeue(queue)

    publish_last_job(queue)
  end

  def process_job(queue, job_json) when is_bitstring(job_json) do
    job_json |> ProcessingLibrary.Job.decode() |> process_job(queue)
  end
end
