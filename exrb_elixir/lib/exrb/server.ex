defmodule Exrb.Server do
  use GenServer

  def start_link(program) do
    GenServer.start_link(__MODULE__, program)
  end

  def call(pid, msg) do
    GenServer.call(pid, {:call, msg})
  end

  ## Callbacks

  def init(program) do
    Process.flag(:trap_exit, true)
    port = Port.open({:spawn, program}, [:binary, packet: 4])
    {:ok, %{port: port, requests: %{}}}
  end

  def handle_call({:call, msg}, from, %{port: port} = state) do
    ref = make_ref
    Port.command(port, :erlang.term_to_binary({ref, msg}))

    :erlang.send_after(5_000, self, {:timeout, ref})

    {:noreply, put_in(state, [:requests, ref], from)}
  end

  def handle_info({:EXIT, port, reason}, %{port: port} = state) do
    {:stop, {:port_terminated, reason}, state}
  end

  def handle_info({:timeout, ref}, %{requests: requests} = state) do
    case Map.pop(requests, ref) do
      {nil, requests} ->
        {:noreply, put_in(state.requests, requests)}
      {_from, _requests} ->
        {:stop, :port_timeout, state}
    end
  end

  def handle_info({port, {:data, payload}}, %{port: port, requests: requests} = state) do
    {ref, msg} = :erlang.binary_to_term(payload)
    {from, requests} = Map.pop(requests, ref)
    GenServer.reply(from, msg)
    {:noreply, put_in(state.requests, requests)}
  end

  def terminate({:port_terminated, _reason}, _state) do
    :ok
  end

  def terminate(_reason, %{port: port}) do
    Port.close(port)
  end
end
