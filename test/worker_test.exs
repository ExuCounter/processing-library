defmodule WorkerTest do
  use ExUnit.Case

  setup do
    {:ok, conn} = ProcessingLibrary.Database.start_link(nil)
    ProcessingLibrary.Database.flush()
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

    queue1 = ProcessingLibrary.Database.get_queue("queue1")
    queue2 = ProcessingLibrary.Database.get_queue("queue2")

    assert {:ok, [_job1]} = queue1
    assert {:ok, [_job2, _job3, _job4]} = queue2

    ProcessingLibrary.QueueWorker.start_link(nil)

    Process.sleep(500)

    queue1 = ProcessingLibrary.Database.get_queue("queue1")
    queue2 = ProcessingLibrary.Database.get_queue("queue2")
    failed_queue = ProcessingLibrary.Database.get_queue(:failed)

    assert {:ok, []} = queue1
    assert {:ok, []} = queue2
    assert {:ok, [_job5]} = failed_queue
  end
end
