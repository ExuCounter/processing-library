defmodule ProcessingLibrary.Enqueuer do
  def enqueue(queue_name, %ProcessingLibrary.Job{} = job_data) do
    encoded_job_data = ProcessingLibrary.Job.encode(job_data)

    with {:ok, _} <- ProcessingLibrary.Database.Queue.enqueue(queue_name, encoded_job_data),
         false <- ProcessingLibrary.is_reserved_queue?(queue_name) do
      ProcessingLibrary.QueueWorker.publish_last_job(queue_name)
      {:ok, job_data}
    else
      error ->
        {:error, error}
    end
  end

  def enqueue(queue_name, worker_module, params) do
    job_data = ProcessingLibrary.Job.construct(worker_module, params)
    enqueue(queue_name, job_data)
  end
end
