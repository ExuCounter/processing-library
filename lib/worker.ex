defmodule ProcessingLibrary.Worker do
  @callback perform(any()) :: any()
end

defmodule ProcessingLibrary.DummyWorker do
  @behaviour ProcessingLibrary.Worker

  def perform(args) do
    IO.inspect(args)
  end
end
