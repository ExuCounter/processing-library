defmodule ProcessingLibrary.Database do
  use GenServer

  @moduledoc """
  This module is responsible for interacting with the database.
  It serves as an abstraction layer over the database, providing a simplified interface
  for performing database operations without exposing the underlying implementation details.

  By using this module, other parts of the application
  can interact with the database in a consistent and reliable way.

  ## Examples

      iex> ProcessingLibrary.Database.get_queues()
      {:ok, [...]}
  """

  defdelegate init(init_arg), to: ProcessingLibrary.Redis, as: :init
  defdelegate start_link(init_arg), to: ProcessingLibrary.Redis, as: :start_link
  defdelegate get_queues(opts), to: ProcessingLibrary.Redis, as: :get_queues
  defdelegate get_queues(), to: ProcessingLibrary.Redis, as: :get_queues
  defdelegate get_queue(queue), to: ProcessingLibrary.Redis, as: :get_queue
  defdelegate get_keys(), to: ProcessingLibrary.Redis, as: :get_keys
  defdelegate set(key, value), to: ProcessingLibrary.Redis, as: :set
  defdelegate flush(), to: ProcessingLibrary.Redis, as: :flush_db
end
