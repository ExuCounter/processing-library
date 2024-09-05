defmodule ProcessingLibrary.Job do
  defstruct params: [], worker_module: nil, queue: nil, jid: nil
end
