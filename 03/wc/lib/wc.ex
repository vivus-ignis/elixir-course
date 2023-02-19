defmodule Wc do
  @num_processes 16

  @spec start_workers(pos_integer()) :: [pid()]
  def start_workers(num) do
    Enum.map(
      1..num,
      fn _ -> spawn(Wc, :word_counter, [self(), 0]) end
    )
  end

  @spec process_file(String.t()) :: non_neg_integer()
  def process_file(filepath) do
    pids = start_workers(@num_processes)

    File.read!(filepath)
    |> String.split("\n", trim: true)
    |> Enum.chunk_every(@num_processes)
    |> Enum.map(fn chunk ->
      Enum.zip(pids, chunk)
      |> Enum.each(fn {pid, data} ->
        send(pid, {:data, data})
      end)
    end)

    Enum.reduce(pids, 0, fn pid, acc ->
      send(pid, :stop)

      receive do
        x -> acc + x
      end
    end)
  end

  @spec word_counter(pid(), non_neg_integer()) :: atom()
  def word_counter(caller, cnt) do
    # IO.puts("counter process #{inspect(self())} started")

    receive do
      {:data, x} ->
        # IO.puts("process #{inspect(self())} received data")
        result = x |> String.split() |> length
        word_counter(caller, cnt + result)

      :stop ->
        # IO.puts("process #{inspect(self())} received stop message")
        send(caller, cnt)
    end

    :ok
  end
end
