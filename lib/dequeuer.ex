defmodule ProcessingLibrary.Dequeuer do
  def remove(queue_name, job_id) do
    {:ok, jobs} = ProcessingLibrary.Database.get_queue(queue_name)
    job = Enum.find(jobs, fn job -> ProcessingLibrary.Job.deserialize(job).jid == job_id end)

    with :ok <- ProcessingLibrary.Queue.remove(queue_name, job) do
      {:ok, ProcessingLibrary.Job.deserialize(job)}
    end
  end

  defdelegate dequeue(queue), to: ProcessingLibrary.Redis, as: :dequeue
end
