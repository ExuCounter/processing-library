defmodule ProcessingLibrary.Env do
  def get_redis_namespace() do
    Application.fetch_env!(:processing_library, :redis_namespace)
  end

  def get_redis_database() do
    Application.fetch_env!(:processing_library, :redis_database)
  end

  def get_redis_port() do
    Application.fetch_env!(:processing_library, :redis_port)
  end

  def get_redis_host() do
    Application.fetch_env!(:processing_library, :redis_host)
  end
end
