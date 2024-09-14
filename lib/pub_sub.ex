defmodule ProcessingLibrary.PubSub do
  @moduledoc """
  This module is responsible for interacting with the pub/sub notifications. It serves as an abstraction layer over the pub/sub mechanism, providing a simplified interface for performing such operations without exposing the underlying implementation details.

  By using this module, other parts of the application can interact with the pub/sub functionality in a consistent and reliable way.

  ## Examples

      iex> ProcessingLibrary.PubSub.publish("channel", "value")
      {:ok, 1}
  """

  defdelegate start_link(), to: Redix.PubSub, as: :start_link
  defdelegate publish(channel, value), to: ProcessingLibrary.Redis, as: :publish
end
