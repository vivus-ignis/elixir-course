defmodule WcTest do
  use ExUnit.Case
  doctest Wc

  @services_file Path.join(["test", "assets", "services"])
  @protocols_file Path.join(["test", "assets", "protocols"])

  test "counts words in files" do
    assert Wc.process_file(@services_file) == 22998
    assert Wc.process_file(@protocols_file) == 412
  end
end
