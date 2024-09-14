defmodule DequeuerTest do
  use ExUnit.Case

  setup do
    {:ok, conn} = ProcessingLibrary.Database.start_link(nil)
    ProcessingLibrary.Database.flush()
    %{conn: conn}
  end

  describe "dequeue/1" do
    test "retrieves elements based on FIFO principle" do
      queue_name = "queue"

      {:ok, job1} =
        ProcessingLibrary.Enqueuer.enqueue(queue_name, ProcessingLibrary.DummyWorker, ["param1"])

      {:ok, job2} =
        ProcessingLibrary.Enqueuer.enqueue(queue_name, ProcessingLibrary.DummyWorker, ["param2"])

      {:ok, dequeued_job1} = ProcessingLibrary.Dequeuer.dequeue(queue_name)
      {:ok, dequeued_job2} = ProcessingLibrary.Dequeuer.dequeue(queue_name)
      {:ok, dequeued_job3} = ProcessingLibrary.Dequeuer.dequeue(queue_name)

      parsed_dequeued_job1 = ProcessingLibrary.Job.deserialize(dequeued_job1)
      parsed_dequeued_job2 = ProcessingLibrary.Job.deserialize(dequeued_job2)

      assert parsed_dequeued_job1.jid == job1.jid
      assert parsed_dequeued_job2.jid == job2.jid
      assert dequeued_job3 == nil
    end
  end

  describe "remove/1" do
    test "removes element from the queue by job id" do
      queue_name = "queue"

      {:ok, job1} =
        ProcessingLibrary.Enqueuer.enqueue(queue_name, ProcessingLibrary.DummyWorker, ["param1"])

      {:ok, job2} =
        ProcessingLibrary.Enqueuer.enqueue(queue_name, ProcessingLibrary.DummyWorker, ["param2"])

      queue = ProcessingLibrary.Database.get_queue(queue_name)

      assert {:ok, [_job1, _job2]} = queue

      ProcessingLibrary.Dequeuer.remove(queue_name, job1.jid)

      queue = ProcessingLibrary.Database.get_queue(queue_name)

      serialized_job2 = ProcessingLibrary.Job.serialize(job2)

      assert {:ok, [serialized_job2]} == queue
    end
  end
end
