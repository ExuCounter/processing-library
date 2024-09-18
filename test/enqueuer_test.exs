defmodule EnqueuerTest do
  use ExUnit.Case

  setup do
    {:ok, conn} = ProcessingLibrary.Database.start_link(nil)
    ProcessingLibrary.Database.flush()
    %{conn: conn}
  end

  test "check that enqueue is saving serialized data to the database" do
    {:ok, job1} =
      ProcessingLibrary.Enqueuer.enqueue("queue1", ProcessingLibrary.DummyWorker, ["param0"])

    {:ok, job2} =
      ProcessingLibrary.Enqueuer.enqueue("queue2", ProcessingLibrary.DummyWorker, ["param1"])

    {:ok, job3} =
      ProcessingLibrary.Enqueuer.enqueue("queue2", ProcessingLibrary.DummyWorker, ["param2"])

    {:ok, job4} =
      ProcessingLibrary.Enqueuer.enqueue(
        "queue2",
        ProcessingLibrary.Job.construct(ProcessingLibrary.DummyWorker, ["param3"])
      )

    queue1 = ProcessingLibrary.Database.get_queue("queue1")
    queue2 = ProcessingLibrary.Database.get_queue("queue2")

    encoded_job1 = ProcessingLibrary.Job.encode(job1)
    encoded_job2 = ProcessingLibrary.Job.encode(job2)
    encoded_job3 = ProcessingLibrary.Job.encode(job3)
    encoded_job4 = ProcessingLibrary.Job.encode(job4)

    assert {:ok, [encoded_job1]} == queue1
    assert {:ok, [encoded_job4, encoded_job3, encoded_job2]} == queue2
  end
end
