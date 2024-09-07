defmodule RedisTest do
  use ExUnit.Case

  setup do
    {:ok, conn} = ProcessingLibrary.Redis.start_link(nil)
    ProcessingLibrary.Redis.flush_db()
    %{conn: conn}
  end

  test "only queues supported" do
    job = %{
      params: ["param"],
      worker_module: ProcessingLibrary.SimpleWorker,
      queue: "queue",
      jid: "jid"
    }

    ProcessingLibrary.Redis.enqueue("queue1", Jason.encode!(job))
    ProcessingLibrary.Redis.enqueue("queue2", Jason.encode!(job))

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
