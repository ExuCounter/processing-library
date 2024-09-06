defmodule ProcessingLibrary.SimpleWorker do
  @behaviour ProcessingLibrary.Worker

  def perform(args) do
    IO.inspect(args)
  end
end

defmodule ProcessingLibrary do
  require Logger

  def get_namespace() do
    Application.fetch_env!(:processing_library, :namespace)
  end

  def log_context(%ProcessingLibrary.Job{worker_module: worker_module, jid: jid}) do
    "#{worker_module}[#{jid}]"
  end

  def publish_last_task(queue_name) do
    {:ok, json} = ProcessingLibrary.Redis.get_last_in_queue(queue_name)
    ProcessingLibrary.Redis.publish("main", json)
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

  def process_task(%ProcessingLibrary.Job{
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
      ProcessingLibrary.publish_last_task(queue_name)
    rescue
      e ->
        Logger.error(
          "#{log_context(%ProcessingLibrary.Job{worker_module: worker_module, jid: jid})})} failed with exception"
        )

        reraise e, __STACKTRACE__
    end
  end

  def process_task(job_json) do
    job = struct(ProcessingLibrary.Job, Jason.decode!(job_json, keys: :atoms))
    process_task(job)
  end
end
