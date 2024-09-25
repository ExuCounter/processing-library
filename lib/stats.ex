defmodule ProcessingLibrary.Stats do
  @stats_queues [:processed, :failed]

  def is_stats_queue?(queue) do
    Enum.member?(@stats_queues, queue)
  end

  def stat(:failed) do
    {:ok, jobs} = ProcessingLibrary.Database.get_queue(:failed)
    length(jobs)
  end

  def stat(:processed) do
    {:ok, jobs} = ProcessingLibrary.Database.get_queue(:processed)
    length(jobs)
  end

  def stat(:scheduled) do
    {:ok, queues} = ProcessingLibrary.Database.get_queues()

    queues
    |> Enum.reduce(0, fn queue, acc ->
      {:ok, jobs} = ProcessingLibrary.Database.get_queue(queue)
      acc + length(jobs)
    end)
  end

  def stats() do
    (@stats_queues ++ [:scheduled])
    |> Enum.reduce(%{}, fn s, acc ->
      Map.put(acc, s, stat(s))
    end)
  end

  def job_info(job_id) do
    {:ok, queues} = ProcessingLibrary.Database.get_queues()

    jobs =
      Enum.map(queues, fn queue -> ProcessingLibrary.Database.get_queue(queue) end)
      |> Enum.reduce([], fn {:ok, jobs}, acc ->
        acc ++ jobs
      end)

    job = Enum.find(jobs, fn job -> ProcessingLibrary.Job.decode(job).jid == job_id end)

    case job do
      nil -> {:error, "Job not found"}
      _ -> ProcessingLibrary.Job.decode(job)
    end
  end
end
