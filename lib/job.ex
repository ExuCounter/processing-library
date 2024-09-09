defmodule ProcessingLibrary.Job do
  @derive {Jason.Encoder, only: [:params, :worker_module, :queue, :jid]}
  defstruct params: [], worker_module: nil, queue: nil, jid: nil
  require Logger

  def log_context(%ProcessingLibrary.Job{worker_module: worker_module, jid: jid}) do
    "#{worker_module}[#{jid}]"
  end

  def publish_last_job(queue_name) do
    {:ok, job_json} = ProcessingLibrary.Redis.get_last_in_queue(queue_name)

    if not is_nil(job_json) do
      ProcessingLibrary.Redis.publish(queue_name, job_json)
    end
  end

  def construct(queue_name, worker_module, params) do
    %ProcessingLibrary.Job{
      params: params,
      worker_module: worker_module,
      queue: queue_name,
      jid: UUID.uuid4()
    }
  end

  def process_job(%ProcessingLibrary.Job{
        worker_module: worker_module,
        params: params,
        queue: queue_name,
        jid: jid
      }) do
    Logger.info(
      "#{log_context(%ProcessingLibrary.Job{worker_module: worker_module, jid: jid})} start"
    )

    try do
      start_time = DateTime.utc_now()
      apply(worker_module |> String.to_atom(), :perform, [params])
      finish_time = DateTime.utc_now()
      diff_time = DateTime.diff(finish_time, start_time, :millisecond)

      Logger.info(
        "#{log_context(%ProcessingLibrary.Job{worker_module: worker_module, jid: jid})} )} finished in #{diff_time}ms"
      )

      ProcessingLibrary.Redis.dequeue(queue_name)
      ProcessingLibrary.Job.publish_last_job(queue_name)
    rescue
      e ->
        Logger.error(
          "#{log_context(%ProcessingLibrary.Job{worker_module: worker_module, jid: jid})})} failed with exception"
        )

        reraise e, __STACKTRACE__
    end
  end

  def process_job(job_json) do
    job = struct(ProcessingLibrary.Job, Jason.decode!(job_json, keys: :atoms))
    process_job(job)
  end
end
