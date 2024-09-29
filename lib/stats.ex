defmodule ProcessingLibrary.Stats do
  @stats_queues [:processed, :failed]

  def is_stats_queue?(queue) do
    Enum.member?(@stats_queues, queue)
  end

  def stat(queue) when queue in @stats_queues do
    {:ok, jobs} = ProcessingLibrary.Database.get_queue(queue)
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
end
