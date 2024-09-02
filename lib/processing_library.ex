defmodule ProcessingLibrary.SimpleWorker do
  @behaviour ProcessingLibrary.Worker

  def perform(args) do
    IO.inspect(args)
  end
end

defmodule ProcessingLibrary do
  def dequeue(queue_name) do
    {:ok, json} = ProcessingLibrary.Redis.dequeue(queue_name)
    job_data = Jason.decode!(json)
    apply(job_data["module_name"] |> String.to_atom(), :perform, [job_data["params"]])
  end

  def enqueue(queue_name, worker_module, params) do
    job_data = %{
      "params" => params,
      "module_name" => worker_module,
      "queue" => queue_name
    }

    json = Jason.encode!(job_data)

    ProcessingLibrary.Redis.queue(queue_name, json)
  end
end
