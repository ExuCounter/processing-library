defmodule ProcessingLibrary.Worker do
  @callback perform(any()) :: any()
end
