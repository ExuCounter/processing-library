defmodule ProcessingLibrary do
  @moduledoc """
  The main module of the processing library, responsible for delegating key operations such as `enqueue`, `dequeue`, `remove`, and `stats` to specialized modules.

  This module acts as a central interface for processing tasks, abstracting the underlying complexity of individual operations and allowing for efficient task management.

  ## Delegated Methods

  - `enqueue/2 or enqueue/1` - Adds a task to the queue.
  - `dequeue/1` - Removes and returns the next task from the queue.
  - `remove/2` - Removes a specific task from the queue.
  - `stats/1` - Retrieves the current statistics from all queues

  By delegating these operations to other modules, `ProcessingLibrary` ensures a clean separation of concerns, making the codebase more modular and maintainable.

  ## Examples

      iex> ProcessingLibrary.enqueue(:queue_name, job)
      {:ok, %ProcessingLibrary.Job{...}}

      iex> ProcessingLibrary.enqueue(:queue_name, ProcessingLibrary.DummyWorker, :param1, :param2)
      {:ok, %ProcessingLibrary.Job{...}}

      iex> ProcessingLibrary.dequeue(:queue_name)
      {:ok, %ProcessingLibrary.Job{...}}

      TODO
      iex> ProcessingLibrary.remove(:queue_name, task_id)
      :ok

      iex> ProcessingLibrary.stats()
      %{processed: 105, scheduled: 70, failed: 5}
  """

  def is_reserved_queue?(queue), do: ProcessingLibrary.Stats.is_stats_queue?(queue)

  defdelegate enqueue(queue, worker_module, params),
    to: ProcessingLibrary.Enqueuer,
    as: :enqueue

  defdelegate enqueue(queue, job_data),
    to: ProcessingLibrary.Enqueuer,
    as: :enqueue

  defdelegate remove(job_id),
    to: ProcessingLibrary.Dequeuer,
    as: :remove

  defdelegate find_job(job_id),
    to: ProcessingLibrary.Dequeuer,
    as: :find_job

  defdelegate stats(),
    to: ProcessingLibrary.Stats,
    as: :stats
end
