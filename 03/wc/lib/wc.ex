defmodule Wc do
  @num_processes 16

  @spec start_workers(pos_integer()) :: [pid()]
  def start_workers(num) do
    Enum.map(
      1..num,
      fn _ -> spawn(Wc, :word_counter, [0]) end
    )
  end

  @spec process_file(String.t()) :: non_neg_integer()
  def process_file(filepath) do
    pids = start_workers(@num_processes)

    File.stream!(filepath)
    |> Stream.chunk_every(@num_processes)
    |> Stream.map(fn chunk ->
      Stream.zip(pids, chunk)
      |> Enum.each(fn {pid, data} ->
        send(pid, {:data, data})
      end)
    end)
    |> Stream.run()

    Task.async_stream(pids, fn pid ->
      send(pid, {:stop, self()})

      receive do
        x -> x
      end
    end)
    |> Enum.reduce(0, fn {:ok, count}, acc -> acc + count end)
  end

  @spec word_counter(non_neg_integer()) :: atom()
  def word_counter(cnt) do
    # IO.puts("counter process #{inspect(self())} started")

    receive do
      {:data, x} ->
        # IO.puts("process #{inspect(self())} received data")
        result = x |> String.split() |> length()
        word_counter(cnt + result)

      {:stop, caller} ->
        # IO.puts("process #{inspect(self())} received stop message")
        send(caller, cnt)
    end

    :ok
  end
end
