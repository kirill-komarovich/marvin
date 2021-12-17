defmodule Marvin.Pipeline.BuilderTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  defmodule ModPipeline do
    import Marvin.Event

    @behaviour Marvin.Pipeline

    def init(opts) do
      {__MODULE__, :init, opts}
    end

    def call(event, opts) do
      trace = [{__MODULE__, :call, opts} | event.assigns[:trace]]

      put_assigns(event, :trace, trace)
    end
  end

  defmodule SamplePipeline do
    use Marvin.Pipeline.Builder

    plug ModPipeline
    plug ModPipeline, foo: :bar
    plug :test_function_plug

    def test_function_plug(event, opts) do
      trace = [{:test_function_plug, opts} | event.assigns[:trace]]

      put_assigns(event, :trace, trace)
    end
  end

  defmodule OverridePipeline do
    use Marvin.Pipeline.Builder

    def call(event, opts) do
      try do
        super(event, opts)
      catch
        :throw, {:error_raised, event} -> put_assigns(event, :error_caught, true)
      end
    end

    plug :raise_error

    def raise_error(event, _opts) do
      event = put_assigns(event, :error_raised, true)

      throw({:error_raised, event})
    end
  end

  defmodule HaltedPipeline do
    use Marvin.Pipeline.Builder

    plug :first
    plug :second
    plug :third

    def first(event, _opts), do: put_assigns(event, :first, true)

    def second(event, _opts), do: event |> put_assigns(:second, true) |> halt()

    def third(event, _opts), do: put_assigns(event, :third, true)
  end

  defmodule InvalidReturnModulePipeline do
    defmodule InvalidReturnPipeline do
      def init([]), do: []

      # Doesn't return a Marvin.Event
      def call(_event, _opts), do: nil
    end

    use Marvin.Pipeline.Builder

    plug InvalidReturnPipeline
  end

  defmodule InvalidReturnFunctionPipeline do
    use Marvin.Pipeline.Builder

    plug :invalid_return_function

    # Doesn't return a Marvin.Event
    def invalid_return_function(_event, _opts), do: nil
  end

  defmodule HaltedWithLogFunctionPipeline do
    use Marvin.Pipeline.Builder, log_on_halt: :info

    plug :log_on_halt

    def log_on_halt(event, _opts), do: event |> put_assigns(:second, true) |> halt()
  end

  defmodule HaltedWithLogModulePipeline do
    defmodule HaltPipeline do
      def init(opts), do: opts

      def call(event, _opts), do: Marvin.Event.halt(event)
    end

    use Marvin.Pipeline.Builder, log_on_halt: :info

    plug HaltPipeline
  end

  test "registers and builds pipelines in order" do
    event = Marvin.Event.put_assigns(%Marvin.Event{}, :trace, [])

    assert SamplePipeline.call(event, []).assigns[:trace] == [
             {:test_function_plug, []},
             {ModPipeline, :call, {ModPipeline, :init, [foo: :bar]}},
             {ModPipeline, :call, {ModPipeline, :init, []}}
           ]
  end

  test "allows to override call/2" do
    event = OverridePipeline.call(%Marvin.Event{}, [])

    assert event.assigns[:error_raised] == true
    assert event.assigns[:error_caught] == true
  end

  test "halts pipelines if event has been halted" do
    event = HaltedPipeline.call(%Marvin.Event{}, [])

    assert event.assigns[:first] == true
    assert event.assigns[:second] == true
    refute Map.has_key?(event.assigns, :third)
  end

  test "raises exception when pipeline does not return event" do
    assert_raise RuntimeError, fn ->
      InvalidReturnModulePipeline.call(%Marvin.Event{}, [])
    end

    assert_raise RuntimeError, fn ->
      InvalidReturnFunctionPipeline.call(%Marvin.Event{}, [])
    end
  end

  test "raises exception when module pipeline does not respond to call/2" do
    assert_raise ArgumentError, fn ->
      defmodule ModulePlugWithoutCallPipeline do
        defmodule PlugWithoutCallPipeline do
          def init([]), do: []
        end

        use Marvin.Pipeline.Builder

        plug PlugWithoutCallPipeline
      end
    end
  end

  test "with log_on_halt option logs event halt" do
    fun_pipeline = fn -> HaltedWithLogFunctionPipeline.call(%Marvin.Event{}, []) end
    module_pipeline = fn -> HaltedWithLogModulePipeline.call(%Marvin.Event{}, []) end

    assert capture_log(fun_pipeline) =~
             ~r"\[info\]  #{inspect(HaltedWithLogFunctionPipeline)} halted in :log_on_halt/2"u

    assert capture_log(module_pipeline) =~
             ~r"\[info\]  #{inspect(HaltedWithLogModulePipeline)} halted in #{
               inspect(HaltedWithLogModulePipeline.HaltPipeline)
             }.call/2"u
  end
end
