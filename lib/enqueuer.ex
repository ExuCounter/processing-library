defmodule ProcessingLibrary.Enqueuer do
  def enqueue(queue_name, worker_module, params) do
    job_data = ProcessingLibrary.Job.construct(worker_module, params)
    serialized_job_data = ProcessingLibrary.Job.serialize(job_data)
    ProcessingLibrary.Redis.enqueue(queue_name, serialized_job_data)

    {:ok, job_data}
  end

  def enqueue(queue_name, %ProcessingLibrary.Job{} = job_data) do
    serialized_job_data = ProcessingLibrary.Job.serialize(job_data)
    ProcessingLibrary.Redis.enqueue(queue_name, serialized_job_data)

    {:ok, job_data}
  end
end
