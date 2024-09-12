defmodule WorkerTest do
  use ExUnit.Case

  setup do
    {:ok, conn} = ProcessingLibrary.Redis.start_link(nil)
    ProcessingLibrary.Redis.flush_db()
    %{conn: conn}
  end

  test "process jobs" do
    {:ok, _job} =
      ProcessingLibrary.Enqueuer.enqueue("queue1", ProcessingLibrary.DummyWorker, :success)

    {:ok, _job} =
      ProcessingLibrary.Enqueuer.enqueue("queue2", ProcessingLibrary.DummyWorker, :success)

    {:ok, _job} =
      ProcessingLibrary.Enqueuer.enqueue("queue2", ProcessingLibrary.DummyWorker, :fail)

    {:ok, _job} =
      ProcessingLibrary.Enqueuer.enqueue("queue2", ProcessingLibrary.DummyWorker, :success)

    queue1 = ProcessingLibrary.Redis.get_queue("queue1")
    queue2 = ProcessingLibrary.Redis.get_queue("queue2")

    assert {:ok, [_job1]} = queue1
    assert {:ok, [_job1, _job2, _job3]} = queue2

    ProcessingLibrary.QueueWorker.start_link(nil)

    Process.sleep(500)

    queue1 = ProcessingLibrary.Redis.get_queue("queue1")
    queue2 = ProcessingLibrary.Redis.get_queue("queue2")
    dead_letter_queue = ProcessingLibrary.Redis.get_queue("dead-letter")

    assert {:ok, []} == queue1
    assert {:ok, []} == queue2
    assert {:ok, [_job1]} == dead_letter_queue
  end
end
