defmodule ProcessingLibrary.SimpleWorker do
  @behaviour ProcessingLibrary.Worker

  def perform(args) do
    IO.inspect(args)
  end
end

defmodule ProcessingLibrary do
  require Logger

  def log_context(%ProcessingLibrary.Job{worker_module: worker_module, jid: jid}) do
    "#{worker_module}[#{jid}]"
  end

  def dequeue(queue_name) do
    {:ok, json} = ProcessingLibrary.Redis.get_last_in_queue(queue_name)
    job = struct(ProcessingLibrary.Job, Jason.decode!(json, keys: :atoms))

    Logger.info("#{log_context(job)} start")

    try do
      start_time = DateTime.utc_now()
      apply(job.worker_module |> String.to_atom(), :perform, [job.params])
      finish_time = DateTime.utc_now()
      diff_time = DateTime.diff(finish_time, start_time, :millisecond)
      Logger.info("#{log_context(job)} finished in #{diff_time}ms")
      ProcessingLibrary.Redis.dequeue(queue_name)
    rescue
      e ->
        Logger.error("#{log_context(job)} failed with exception")
        reraise e, __STACKTRACE__
    end
  end

  def prepare_job_data(queue_name, worker_module, params) do
    %{
      params: params,
      worker_module: worker_module,
      queue: queue_name,
      jid: UUID.uuid4()
    }
  end

  def enqueue(queue_name, worker_module, params) do
    job_data = prepare_job_data(queue_name, worker_module, params)
    json = Jason.encode!(job_data)
    ProcessingLibrary.Redis.queue(queue_name, json)
  end
end
