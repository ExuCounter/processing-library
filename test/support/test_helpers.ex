defmodule ProcessingLibrary.DummyWorker do
  @behaviour ProcessingLibrary.Worker

  def perform("fail") do
    Process.sleep(100)
    raise "Oops... Something went wrong"
  end

  def perform(_) do
  end
end
