defmodule StatsTest do
  use ExUnit.Case

  setup do
    {:ok, conn} = ProcessingLibrary.Database.start_link(nil)
    ProcessingLibrary.Database.flush()
    %{conn: conn}
  end

  test "stats" do
    queue_name = "queue"

    ProcessingLibrary.Enqueuer.enqueue(queue_name, ProcessingLibrary.DummyWorker, "success")
    ProcessingLibrary.Enqueuer.enqueue(queue_name, ProcessingLibrary.DummyWorker, "fail")
    ProcessingLibrary.Enqueuer.enqueue(queue_name, ProcessingLibrary.DummyWorker, "success")

    assert %{processed: 0, scheduled: 3, failed: 0} == ProcessingLibrary.Stats.stats()

    ProcessingLibrary.QueueWorker.start_link(nil)

    Process.sleep(500)

    assert %{processed: 2, scheduled: 0, failed: 1} == ProcessingLibrary.Stats.stats()

    GenServer.stop(ProcessingLibrary.QueueWorker)

    ProcessingLibrary.Enqueuer.enqueue(queue_name, ProcessingLibrary.DummyWorker, "fail")

    assert %{processed: 2, scheduled: 1, failed: 1} == ProcessingLibrary.Stats.stats()
  end
end
