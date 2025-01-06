defmodule NodeEx.Runtime.Evaluator do
  use GenServer
  require Logger

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Sends code to iex and waits for the evaluation response.
  """
  def evaluate_code(code, opts \\ []) do
    GenServer.call(__MODULE__, {:evaluate, code, opts}, :infinity)
  end

  # Server Callbacks

  @impl true
  def init(_) do
    {iex_evaluator, iex_server} =
      IEx.Broker.evaluator()
      |> IO.inspect(label: Runtime.Evaluator)

    state =
      %{
        caller: nil,
        ref: nil,
        iex_evaluator: iex_evaluator,
        iex_server: iex_server
      }

    {:ok, state}
  end

  @impl true
  def handle_call({:evaluate, code, _opts}, from, %{caller: nil} = state) do
    ref = make_ref()
    normalized_pid = :erlang.pid_to_list(self())
    normalized_ref = :erlang.ref_to_list(ref)

    code =
      """
      try do
        #{code}
      rescue
        error ->
          send(:erlang.list_to_pid(~c"#{normalized_pid}"), {:iex_reply, :erlang.list_to_ref(~c"#{normalized_ref}"), {:error, error}})
      else
        result ->
          send(:erlang.list_to_pid(~c"#{normalized_pid}"), {:iex_reply, :erlang.list_to_ref(~c"#{normalized_ref}"), {:ok, result}})
      end
      IEx.dont_display_result()
      """

    send_to_iex(state, code)
    {:noreply, %{state | caller: from, ref: ref}}
  end

  def handle_call({:evaluate, _code, _opts}, _from, state) do
    {:reply, {:error, :iex_busy}, state}
  end

  @impl true
  def handle_info({:iex_reply, ref, response}, %{caller: caller, ref: ref} = state) do
    GenServer.reply(caller, response)
    {:noreply, %{state | caller: nil, ref: nil}}
  end

  defp send_to_iex(state, code) do
    IO.inspect(state, label: "OK")
    send(state.iex_evaluator, {:eval, state.iex_server, code, 1, ""})
  end
end
