defmodule ProcessingLibrary.Enqueuer do
  def enqueue(queue_name, worker_module, params) do
    job_data = ProcessingLibrary.Job.construct(queue_name, worker_module, params)
    json = Jason.encode!(job_data)
    ProcessingLibrary.Redis.enqueue(queue_name, json)
  end
end
