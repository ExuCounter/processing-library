defmodule ProcessingLibrary.Stats do
  def stat(:dead_letter) do
    {:ok, jobs} = ProcessingLibrary.Redis.get_queue("dead-letter")
    length(jobs)
  end

  def stat(:success) do
    {:ok, jobs} = ProcessingLibrary.Redis.get_queue("success")
    length(jobs)
  end

  def stat(:waiting) do
    {:ok, queues} = ProcessingLibrary.Redis.get_queues()

    queues
    |> Enum.reduce(0, fn queue, acc ->
      {:ok, jobs} = ProcessingLibrary.Redis.get_queue(queue)
      acc + length(jobs)
    end)
  end

  def stats() do
    [:waiting, :dead_letter, :success]
    |> Enum.reduce(%{}, fn s, acc ->
      Map.put(acc, s, stat(s))
    end)
  end
end
