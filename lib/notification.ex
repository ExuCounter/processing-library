defmodule ProcessingLibrary.Notification do
  use GenServer

  def init(init_arg) do
    {:ok, init_arg}
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{pids: []}, name: __MODULE__)
  end

  def notify(action, job, queue) when action in [:create_job, :move_job, :remove_job, :processing_job] do
    GenServer.cast(__MODULE__, {action, job, queue})
  end

  def subscribe(pid) do
    GenServer.cast(__MODULE__, {:subscribe, pid})
  end

  def handle_cast({action, job, queue}, state) do
    Enum.each(state.pids, fn pid ->
      send(pid, {action, job, queue})
    end)

    {:noreply, state}
  end

  def handle_cast({:subscribe, pid}, state) do
    {:noreply, %{state | pids: [pid | state.pids]}}
  end
end
