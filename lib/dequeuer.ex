defmodule ProcessingLibrary.Dequeuer do
  def remove(queue, job_id) do
    {:ok, jobs} = ProcessingLibrary.Database.get_queue(queue)
    job = Enum.find(jobs, fn job -> ProcessingLibrary.Job.decode(job).jid == job_id end)

    case job do
      nil -> {:error, "Job not found"}
      _ -> ProcessingLibrary.Database.Queue.remove(queue, job)
    end
  end

  defdelegate dequeue(queue), to: ProcessingLibrary.Redis, as: :dequeue
end
