defmodule Marvin.PollerTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  defmodule Matcher do
    def call(_) do
    end
  end

  defmodule Endpoint do
    def call(_) do
    end
  end

  defmodule Adapter do
    def name, do: "Adapter"

    def get_updates(state) do
      Map.get(state, :response, {:ok, []})
    end
  end

  defmodule TestPoller do
    use Marvin.Poller, adapter: Adapter, timeout: 10

    assert @adapter == Adapter
    assert @timeout == 10
  end

  @tag capture_log: true
  test "init/2 schedules poll event by given timeout" do
    {:ok, pid} = TestPoller.start_link(Endpoint)
    :erlang.trace(pid, true, [:receive])

    assert_receive {:trace, ^pid, :receive, :poll}, 15
  end

  @tag capture_log: true
  test "init/2 saves endpoint to state" do
    {:ok, %{endpoint: endpoint}} = TestPoller.init({Endpoint, []})

    assert endpoint == Endpoint
  end

  test "init/2 logs poller start" do
    fun = fn -> TestPoller.init({Endpoint, []}) end

    assert capture_log(fun) =~ ~r"\[info\]  Start poll with #{Adapter.name()}"u
  end

  test "__child_spec__/2 returns poller specification" do
    spec = %{id: TestPoller, start: {TestPoller, :start_link, [Endpoint]}}
    assert ^spec = Marvin.Poller.__child_spec__(TestPoller, endpoint: Endpoint)
  end

  test "poll/3 processes updates" do
    state = %{endpoint: Endpoint, response: {:ok, []}}

    assert {:noreply, ^state} = Marvin.Poller.poll(Adapter, state, fn state, _ -> state end)
  end

  test "poll/3 with custom updater returns updated state" do
    state = %{endpoint: Endpoint, value: :static, response: {:ok, []}}
    state_updater = fn state, _ -> %{state | value: :changed} end

    assert {:noreply, %{value: :changed}} = Marvin.Poller.poll(Adapter, state, state_updater)
  end

  test "poll/3 logs error when adapter returns error" do
    error = :some_error
    state = %{endpoint: Endpoint, response: {:error, error}}

    fun = fn ->
      assert {:noreply, ^state} = Marvin.Poller.poll(Adapter, state, fn state, _ -> state end)
    end

    assert capture_log(fun) =~
             ~r"\[error\] Error while polling #{Adapter.name()}\: #{inspect(error)}"u
  end

  @tag capture_log: true
  test "telemetry", %{test: test} do
    self = self()

    :ok =
      :telemetry.attach_many(
        "#{test}",
        [
          [:marvin, :poller, :start],
          [:marvin, :poller, :poll, :error]
        ],
        fn name, measurements, metadata, _ ->
          send(self, {:telemetry_event, name, measurements, metadata})
        end,
        nil
      )

    error = :some_error
    state = %{endpoint: Endpoint, response: {:error, error}}

    TestPoller.init({Endpoint, []})
    Marvin.Poller.poll(Adapter, state, fn state, _ -> state end)

    assert_receive {:telemetry_event, [:marvin, :poller, :start], %{system_time: _},
                    %{adapter: Adapter}}

    assert_receive {:telemetry_event, [:marvin, :poller, :poll, :error], %{system_time: _},
                    %{adapter: adapter, error: error}}

    :telemetry.detach("#{test}")
  end
end
