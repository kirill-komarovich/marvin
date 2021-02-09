defmodule Marvin.PollerTest do
  use ExUnit.Case, async: true

  defmodule Endpoint do
    use Marvin.Endpoint, otp_app: :marvin
  end

  defmodule Adapter do
    use Marvin.Adapter

    @impl true
    def get_updates(_) do
      assert true
    end
  end

  defmodule Poller do
    use Marvin.Poller, adapter: Adapter, timeout: 500

    assert @adapter == Adapter
    assert @timeout == 500
  end

  test "init/2 schedules poll event by given timeout" do
    {:ok, pid} = Poller.start_link(Endpoint)
    :erlang.trace(pid, true, [:receive])

    assert_receive {:trace, ^pid, :receive, :poll}, 600
  end

  test "init/2 saves endpoint to state" do
    {:ok, %{endpoint: endpoint}} = Poller.init({Endpoint, []})

    assert endpoint == Endpoint
  end
end
