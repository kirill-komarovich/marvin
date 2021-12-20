defmodule Marvin.HandlerTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  doctest Marvin.Handler

  defmodule SampleHandler do
    use Marvin.Handler

    import Marvin.Event

    defmodule ModulePlug do
      import Marvin.Event

      def init(opts), do: opts

      def call(event, opts) do
        trace = [{__MODULE__, :call, opts} | event.assigns[:trace]]

        put_assigns(event, :trace, trace)
      end
    end

    plug ModulePlug
    plug ModulePlug, foo: :bar
    plug :function_plug

    def handle(event, params) do
      trace = [{__MODULE__, params} | event.assigns[:trace]]

      put_assigns(event, :trace, trace)
    end

    def function_plug(event, opts) do
      trace = [{:function_plug, opts} | event.assigns[:trace]]

      put_assigns(event, :trace, trace)
    end
  end

  defmodule HaltedHandler do
    use Marvin.Handler

    import Marvin.Event

    plug :halt_plug

    def handle(event, params) do
      trace = [{__MODULE__, params} | event.assigns[:trace]]

      put_assigns(event, :trace, trace)
    end

    def halt_plug(event, opts) do
      trace = [{:halt_plug, opts} | event.assigns[:trace]]

      event
      |> put_assigns(:trace, trace)
      |> halt()
    end
  end

  test "registers and builds pipelines in order" do
    params = %{"key" => "value"}

    event =
      %Marvin.Event{}
      |> Map.put(:params, params)
      |> Marvin.Event.put_assigns(:trace, [])

    assert SampleHandler.call(event, []).assigns[:trace] == [
             {SampleHandler, params},
             {:function_plug, []},
             {SampleHandler.ModulePlug, :call, [foo: :bar]},
             {SampleHandler.ModulePlug, :call, []}
           ]
  end

  test "logs on halt with debug level" do
    handler_call = fn ->
      event =
        %Marvin.Event{}
        |> Map.put(:params, %{"key" => "value"})
        |> Marvin.Event.put_assigns(:trace, [])

      assert HaltedHandler.call(event, []).assigns[:trace] == [{:halt_plug, []}]
    end

    assert capture_log(handler_call) =~
             ~r"\[debug\] #{inspect(HaltedHandler)} halted in :halt_plug/2"u
  end
end
