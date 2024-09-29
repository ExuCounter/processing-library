defmodule ProcessingLibrary.QueueWorker do
  use GenServer
  require Logger

  def init(_) do
    {:ok, queues} = ProcessingLibrary.Database.get_queues()
    start_processing(queues)
    {:ok, %{}}
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def log_context(%ProcessingLibrary.Job{worker_module: worker_module, jid: jid}) do
    "#{worker_module}[#{jid}]"
  end

  def start_processing(queues) do
    Enum.each(queues, fn queue ->
      process_job(queue)
    end)
  end

  def publish_job(queue) do
    GenServer.cast(__MODULE__, {:publish, queue})
  end

  def handle_cast(
        {:publish, queue},
        state
      ) do
    process_job(queue)
    {:noreply, state}
  end

  def process_job(%ProcessingLibrary.Job{} = job, queue) do
    Logger.info("#{log_context(job)} start")

    ProcessingLibrary.Notification.notify(:processing_job, job, queue)
    start_time = DateTime.utc_now()

    try do
      apply(job.worker_module |> String.to_atom(), :perform, [job.params])
      finish_time = DateTime.utc_now()
      diff_time = DateTime.diff(finish_time, start_time, :millisecond)

      Logger.info("#{log_context(job)} )} finished in #{diff_time}ms")

      ProcessingLibrary.Enqueuer.enqueue(:processed, %{
        job
        | start_at: start_time,
          finish_at: finish_time
      })

      ProcessingLibrary.Notification.notify(:move_job, job, queue)
    rescue
      e ->
        finish_time = DateTime.utc_now()
        diff_time = DateTime.diff(finish_time, start_time, :millisecond)

        Logger.error("#{log_context(job)})} failed with exception:\n#{Exception.message(e)}")
        Logger.info("#{log_context(job)} )} finished in #{diff_time}ms")

        ProcessingLibrary.Enqueuer.enqueue(:failed, %{
          job
          | error: ~c"#{Exception.message(e)}",
            start_at: start_time,
            finish_at: finish_time
        })

        ProcessingLibrary.Notification.notify(:move_job, job, queue)
    end

    ProcessingLibrary.Dequeuer.dequeue(queue)
    process_job(queue)
  end

  def process_job(queue) do
    {:ok, job_json} = ProcessingLibrary.Database.Queue.peek(queue, :front)

    if not is_nil(job_json) do
      job_json |> ProcessingLibrary.Job.decode() |> process_job(queue)
    end
  end
end
