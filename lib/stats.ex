defmodule ProcessingLibrary.Stats do
  def stat(:failed) do
    {:ok, jobs} = ProcessingLibrary.Database.get_queue("dead-letter")
    length(jobs)
  end

  def stat(:processed) do
    {:ok, jobs} = ProcessingLibrary.Database.get_queue("success")
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
    [:processed, :scheduled, :failed]
    |> Enum.reduce(%{}, fn s, acc ->
      Map.put(acc, s, stat(s))
    end)
  end
end
