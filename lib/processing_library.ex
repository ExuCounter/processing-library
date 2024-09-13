defmodule ProcessingLibrary do
  defdelegate enqueue(queue_name, worker_module, params),
    to: ProcessingLibrary.Enqueuer,
    as: :enqueue
end
