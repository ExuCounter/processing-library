defmodule DatabaseTest do
  use ExUnit.Case

  setup do
    {:ok, conn} = ProcessingLibrary.Database.start_link(nil)
    ProcessingLibrary.Database.flush()
    %{conn: conn}
  end

  test "track queues only" do
    ProcessingLibrary.Enqueuer.enqueue("queue1", ProcessingLibrary.DummyWorker, ["param"])
    ProcessingLibrary.Enqueuer.enqueue("queue2", ProcessingLibrary.DummyWorker, ["param"])

    ProcessingLibrary.Database.set("dummy_key", "dummy_value")

    {:ok, keys} = ProcessingLibrary.Database.get_keys()
    {:ok, queues} = ProcessingLibrary.Database.get_queues()

    assert Enum.sort(keys) == [
             "processing_library:dummy_key",
             "processing_library:queue1",
             "processing_library:queue2"
           ]

    assert queues == ["processing_library:queue1", "processing_library:queue2"]
  end
end
