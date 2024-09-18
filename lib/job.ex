defmodule ProcessingLibrary.Job do
  @derive {Jason.Encoder, only: [:params, :worker_module, :jid]}
  defstruct params: [], worker_module: nil, jid: nil

  def construct(worker_module, params) do
    %ProcessingLibrary.Job{
      params: params,
      worker_module: worker_module,
      jid: UUID.uuid4()
    }
  end

  def encode(%ProcessingLibrary.Job{} = job), do: Jason.encode!(job)

  def decode(job_json),
    do: struct(ProcessingLibrary.Job, Jason.decode!(job_json, keys: :atoms))
end
