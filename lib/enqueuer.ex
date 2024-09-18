defmodule ProcessingLibrary.Enqueuer do
  def enqueue(queue_name, worker_module, params) do
    job_data = ProcessingLibrary.Job.construct(worker_module, params)
    encoded_job_data = ProcessingLibrary.Job.encode(job_data)
    ProcessingLibrary.Database.Queue.enqueue(queue_name, encoded_job_data)

    {:ok, job_data}
  end

  def enqueue(queue_name, %ProcessingLibrary.Job{} = job_data) do
    encoded_job_data = ProcessingLibrary.Job.encode(job_data)
    ProcessingLibrary.Database.Queue.enqueue(queue_name, encoded_job_data)

    {:ok, job_data}
  end
end
