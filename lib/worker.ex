defmodule ProcessingLibrary.Worker do
  @callback perform(any()) :: any()
end

defmodule ProcessingLibrary.DummyWorker do
  @behaviour ProcessingLibrary.Worker

  def perform("fail") do
    raise "Oops... Something went wrong"
  end

  def perform("success") do
  end
end
