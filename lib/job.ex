defmodule ProcessingLibrary.Job do
  @derive {Jason.Encoder, only: [:params, :worker_module, :jid]}
  defstruct params: [], worker_module: nil, jid: nil
  require Logger

  def log_context(%ProcessingLibrary.Job{worker_module: worker_module, jid: jid}) do
    "#{worker_module}[#{jid}]"
  end

  def publish_last_job(queue_name) do
    {:ok, job_json} = ProcessingLibrary.Queue.get_last(queue_name)

    if not is_nil(job_json) do
      ProcessingLibrary.PubSub.publish(queue_name, job_json)
    end
  end

  def construct(worker_module, params) do
    %ProcessingLibrary.Job{
      params: params,
      worker_module: worker_module,
      jid: UUID.uuid4()
    }
  end

  def serialize(%ProcessingLibrary.Job{} = job), do: Jason.encode!(job)

  def deserialize(job_json),
    do: struct(ProcessingLibrary.Job, Jason.decode!(job_json, keys: :atoms))

  def process_job(%ProcessingLibrary.Job{} = job, queue) do
    Logger.info("#{log_context(job)} start")

    try do
      start_time = DateTime.utc_now()
      apply(job.worker_module |> String.to_atom(), :perform, [job.params])
      finish_time = DateTime.utc_now()
      diff_time = DateTime.diff(finish_time, start_time, :millisecond)

      Logger.info("#{log_context(job)} )} finished in #{diff_time}ms")

      ProcessingLibrary.Enqueuer.enqueue("success", job)
    rescue
      _ ->
        Logger.error("#{log_context(job)})} failed with exception")
        ProcessingLibrary.Enqueuer.enqueue("dead-letter", job)
    end

    ProcessingLibrary.Dequeuer.dequeue(queue)
    ProcessingLibrary.Job.publish_last_job(queue)
  end

  def process_job(queue, job_json) when is_bitstring(job_json) do
    job_json |> deserialize() |> process_job(queue)
  end
end
