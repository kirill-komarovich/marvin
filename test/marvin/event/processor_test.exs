defmodule Marvin.Event.ProcessorTest do
  use ExUnit.Case, async: true

  alias Marvin.Event.Processor

  defmodule Endpoint do
    def call(%{target: target, converted_data: converted_data}, _opts) do
      send(target, {:endpoint, :converted_data, converted_data})
    end
  end

  defmodule FailureEndpoint do
    def call(_, _opts) do
      raise "Error"
    end
  end

  defmodule Adapter do
    def event(%{target: target, data: data}) do
      send(target, {:adapter, :data, data})

      %{target: target, converted_data: :converted_data}
    end
  end

  test "init/1 returns event as process state" do
    assert {:ok, :event} = Processor.init(:event)
  end

  test "handle_cast/2 :process callback converts update to event, put it to endpoint" do
    update = %{target: self(), data: :data}

    {:ok, pid} = start_supervised({Processor, update})

    GenServer.cast(pid, {:process, Endpoint, Adapter})

    assert_receive {:adapter, :data, :data}
    assert_receive {:endpoint, :converted_data, :converted_data}
  end

  test "process/3 start child process for given update and cast :process and shutdown child process" do
    {:ok, pid} = start_supervised(Marvin.Event.Supervisor)

    :erlang.trace(pid, true, [:receive])

    update = %{target: self(), data: :data}

    Processor.process(Endpoint, Adapter, update)

    assert_receive {:trace, ^pid, :receive,
                    {:"$gen_call", _,
                     {:start_child, {{Processor, :start_link, [^update]}, _, _, _, _}}}}

    assert_receive {:trace, ^pid, :receive, {:ack, child_pid, {:ok, _}}}
    assert_receive {:trace, ^pid, :receive, {:EXIT, ^child_pid, :shutdown}}
  end

  test "process/3 when updates is list runs process/3 for each update" do
    {:ok, pid} = start_supervised(Marvin.Event.Supervisor)
    :erlang.trace(pid, true, [:receive])

    [first_update, second_update] =
      updates = [%{target: self(), data: :data1}, %{target: self(), data: :data2}]

    Processor.process(Endpoint, Adapter, updates)

    assert_receive {:trace, ^pid, :receive,
                    {:"$gen_call", _,
                     {:start_child, {{Processor, :start_link, [^first_update]}, _, _, _, _}}}}

    assert_receive {:trace, ^pid, :receive,
                    {:"$gen_call", _,
                     {:start_child, {{Processor, :start_link, [^second_update]}, _, _, _, _}}}}
  end

  @tag capture_log: true
  test "telemetry", %{test: test} do
    self = self()

    update = %{target: self, data: :data}

    :ok =
      :telemetry.attach_many(
        "#{test}",
        [
          [:marvin, :update, :start],
          [:marvin, :update, :stop],
          [:marvin, :update, :exception]
        ],
        fn name, measurements, metadata, _ ->
          send(self, {:telemetry_event, name, measurements, metadata})
        end,
        nil
      )

    {:ok, pid} = start_supervised({Processor, update})
    GenServer.cast(pid, {:process, Endpoint, Adapter})

    assert_receive {:telemetry_event, [:marvin, :update, :start], %{system_time: _},
                    %{endpoint: Endpoint, adapter: Adapter, update: ^update}}

    assert_receive {:telemetry_event, [:marvin, :update, :stop], %{duration: _},
                    %{endpoint: Endpoint, adapter: Adapter, update: ^update}}

    {:ok, pid} = start_supervised({Processor, update})

    GenServer.cast(pid, {:process, FailureEndpoint, Adapter})

    assert_receive {:telemetry_event, [:marvin, :update, :exception], %{duration: _},
                    %{
                      endpoint: FailureEndpoint,
                      adapter: Adapter,
                      update: ^update,
                      reason: reason,
                      stacktrace: stacktrace
                    }}

    assert %{__exception__: true, message: "Error"} = reason

    assert [{Marvin.Event.ProcessorTest.FailureEndpoint, :call, 2, _path} | _] = stacktrace

    :telemetry.detach("#{test}")
  end
end
