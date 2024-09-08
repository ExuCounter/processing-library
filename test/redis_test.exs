defmodule RedisTest do
  use ExUnit.Case

  setup do
    {:ok, conn} = ProcessingLibrary.Redis.start_link(nil)
    ProcessingLibrary.Redis.flush_db()
    %{conn: conn}
  end

  test "only queues supported" do
    ProcessingLibrary.Enqueuer.enqueue("queue1", ProcessingLibrary.DummyWorker, params: ["param"])
    ProcessingLibrary.Enqueuer.enqueue("queue2", ProcessingLibrary.DummyWorker, params: ["param"])

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
