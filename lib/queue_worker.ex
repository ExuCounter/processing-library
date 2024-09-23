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
      process_last_job(queue)
    end)
  end

  defp process_last_job(queue_name) do
    {:ok, job_json} = ProcessingLibrary.Database.Queue.peek(queue_name, :front)

    if not is_nil(job_json) do
      process_job(job_json, queue_name)
    end
  end

  def publish_last_job(queue_name) do
    {:ok, job_json} = ProcessingLibrary.Database.Queue.peek(queue_name, :front)

    if not is_nil(job_json) do
      GenServer.cast(__MODULE__, {:publish, queue_name, job_json})
    end
  end

  def handle_cast(
        {:publish, queue_name, job_json},
        state
      ) do
    process_job(job_json, queue_name)
    {:noreply, state}
  end

  def process_job(%ProcessingLibrary.Job{} = job, queue) do
    Logger.info("#{log_context(job)} start")

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
    rescue
      e ->
        finish_time = DateTime.utc_now()
        Logger.error("#{log_context(job)})} failed with exception:\n#{Exception.message(e)}")

        ProcessingLibrary.Enqueuer.enqueue(:failed, %{
          job
          | error: ~c"#{Exception.message(e)}",
            start_at: start_time,
            finish_at: finish_time
        })
    end

    ProcessingLibrary.Dequeuer.dequeue(queue)
    process_last_job(queue)
  end

  def process_job(job_json, queue) when is_bitstring(job_json) do
    job_json |> ProcessingLibrary.Job.decode() |> process_job(queue)
  end
end
