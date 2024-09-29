defmodule ProcessingLibrary.Dequeuer do
  def find_job(job_id) do
    {:ok, queues} = ProcessingLibrary.Database.get_queues(include_reserved: true)

    jobs =
      Enum.flat_map(queues, fn queue ->
        case ProcessingLibrary.Database.get_queue(queue) do
          {:ok, jobs} -> Enum.map(jobs, fn job -> {job, queue} end)
          _ -> []
        end
      end)

    job = Enum.find(jobs, fn {job, _queue} -> ProcessingLibrary.Job.decode(job).jid == job_id end)

    case job do
      nil -> {:error, "Job not found"}
      {job, queue} -> {:ok, ProcessingLibrary.Job.decode(job), queue}
    end
  end

  def remove(job_id) do
    with {:ok, job, queue} <- find_job(job_id) do
      job_json = ProcessingLibrary.Job.encode(job)
      ProcessingLibrary.Database.Queue.remove(queue, job_json)
      ProcessingLibrary.Notification.notify(:remove_job, job, queue)
    else
      _ -> {:error, "Job not found"}
    end
  end

  defdelegate dequeue(queue), to: ProcessingLibrary.Database.Queue, as: :dequeue
end
