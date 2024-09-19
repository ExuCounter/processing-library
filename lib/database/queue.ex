defmodule ProcessingLibrary.Database.Queue do
  @moduledoc """
  This module is responsible for interacting with the queues in database. It serves as an abstraction layer over the queue data structure, providing a simplified interface for performing such operations without exposing the underlying implementation details.

  By using this module, other parts of the application can interact with the queues in a consistent and reliable way.

  ## Examples

      iex> ProcessingLibrary.Database.Queue.enqueue("queue", "value")
      {:ok, 1}

      iex> ProcessingLibrary.Database.Queue.dequeue("queue")
      {:ok, "value"}
  """

  defdelegate enqueue(queue, value), to: ProcessingLibrary.Redis, as: :enqueue
  defdelegate dequeue(queue), to: ProcessingLibrary.Redis, as: :dequeue
  defdelegate remove(queue, value), to: ProcessingLibrary.Redis, as: :remove
  defdelegate peek(queue, position), to: ProcessingLibrary.Redis, as: :peek
end
