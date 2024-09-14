defmodule ProcessingLibrary.Dequeuer do
  def remove(queue_name, job_data) do
    serialized_job_data = ProcessingLibrary.Job.serialize(job_data)
    ProcessingLibrary.Queue.remove(queue_name, serialized_job_data)

    {:ok, job_data}
  end

  defdelegate dequeue(queue), to: ProcessingLibrary.Redis, as: :dequeue
end
