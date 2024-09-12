defmodule RedisTest do
  use ExUnit.Case

  setup do
    {:ok, conn} = ProcessingLibrary.Redis.start_link(nil)
    ProcessingLibrary.Redis.flush_db()
    %{conn: conn}
  end

  test "track queues only" do
    ProcessingLibrary.Enqueuer.enqueue("queue1", ProcessingLibrary.DummyWorker, ["param"])
    ProcessingLibrary.Enqueuer.enqueue("queue2", ProcessingLibrary.DummyWorker, ["param"])

    ProcessingLibrary.Redis.set("dummy_key", "dummy_value")

    {:ok, keys} = ProcessingLibrary.Redis.get_keys()
    {:ok, queues} = ProcessingLibrary.Redis.get_queues()

    assert keys == [
             "processing_library:dummy_key",
             "processing_library:queue2",
             "processing_library:queue1"
           ]

    assert queues == ["processing_library:queue2", "processing_library:queue1"]
  end
end
