defmodule ProcessingLibraryTest do
  use ExUnit.Case
  doctest ProcessingLibrary

  test "greets the world" do
    assert ProcessingLibrary.hello() == :world
  end
end
