defmodule Mix.Tasks.Mvn.NewTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO
  import Support.TmpDirs
  import Support.FileAssertions

  @app_name "mvn_app"

  setup_all do
    Mix.shell(Mix.Shell.Process)

    :ok
  end

  test "new with defaults", %{test: test} do
    in_tmp(test, fn ->
      Mix.Tasks.Mvn.New.run([@app_name])

      assert_file("#{@app_name}/README.md")
      assert_file("#{@app_name}/.gitignore")

      assert_file("#{@app_name}/.formatter.exs", fn file ->
        assert file =~ "import_deps: [:marvin]"
        assert file =~ "inputs: [\"*.{ex,exs}\", \"{config,lib,test}/**/*.{ex,exs}\"]"
      end)

      assert_file("#{@app_name}/mix.exs", fn file ->
        assert file =~ "app: :#{@app_name}"
        assert file =~ "mod: {MvnApp.Application, []}"
      end)

      assert_file(
        "#{@app_name}/lib/#{@app_name}/application.ex",
        ~r/defmodule MvnApp.Application do/
      )

      assert_file("#{@app_name}/lib/#{@app_name}.ex", ~r/defmodule MvnApp do/)

      assert_file("#{@app_name}/lib/#{@app_name}_bot.ex", fn file ->
        assert file =~ "defmodule MvnAppBot do"
        assert file =~ "use Marvin.Handler\n\n      import Marvin.Event"
        assert file =~ "use Marvin.Matcher"
      end)

      assert_file("#{@app_name}/test/test_helper.exs")

      assert_file("#{@app_name}/test/support/event_case.ex", fn file ->
        assert file =~ ~r/defmodule MvnAppBot.EventCase/
        assert file =~ "@endpoint MvnAppBot.Endpoint"
      end)

      assert_file("#{@app_name}/lib/#{@app_name}_bot/handlers/hello_handler.ex", fn file ->
        assert file =~ ~r/defmodule MvnAppBot.HelloHandler/
        assert file =~ "use MvnAppBot, :handler"
      end)

      assert_file("#{@app_name}/lib/#{@app_name}_bot/handlers/unknown_handler.ex", fn file ->
        assert file =~ ~r/defmodule MvnAppBot.UnknownHandler/
        assert file =~ "use MvnAppBot, :handler"
      end)

      assert_file("#{@app_name}/lib/#{@app_name}_bot/matcher.ex", fn file ->
        assert file =~ "defmodule MvnAppBot.Matcher"
        assert file =~ "handle ~m\"hello\", MvnAppBot.HelloHandler"
        assert file =~ "handle ~r/.*/, MvnAppBot.UnknownHandler"
      end)

      assert_file("#{@app_name}/lib/#{@app_name}_bot/endpoint.ex", fn file ->
        assert file =~ ~s"defmodule MvnAppBot.Endpoint"
        assert file =~ ~s"plug Marvin.Pipeline.Logger"
        assert file =~ ~s"plug MvnAppBot.Matcher"
      end)

      assert_file("#{@app_name}/mix.exs", fn file ->
        assert file =~ "{:telemetry_metrics,"
        assert file =~ "{:telemetry_poller,"
      end)

      assert_file("#{@app_name}/lib/#{@app_name}_bot/telemetry.ex", fn file ->
        assert file =~ "defmodule MvnAppBot.Telemetry do"
        assert file =~ "{:telemetry_poller, measurements: periodic_measurements()"
        assert file =~ "defp periodic_measurements do"
        assert file =~ "# {MvnAppBot, :count_users, []}"
        assert file =~ "def metrics do"
        assert file =~ "summary(\"marvin.endpoint.stop.duration\","
      end)
    end)
  end

  test "new with path, app and module", %{test: test} do
    in_tmp(test, fn ->
      custom_path = "custom_path"
      project_path = Path.join(File.cwd!(), custom_path)
      Mix.Tasks.Mvn.New.run([project_path, "--app", @app_name, "--module", "MarvinApp"])

      assert_file("#{custom_path}/.gitignore")
      assert_file("#{custom_path}/.gitignore", ~r/\n$/)
      assert_file("#{custom_path}/mix.exs", ~r/app: :#{@app_name}/)
      assert_file("#{custom_path}/lib/#{@app_name}.ex", "defmodule MarvinApp do")
    end)
  end

  test "new with telegram option", %{test: test} do
    in_tmp(test, fn ->
      Mix.Tasks.Mvn.New.run([@app_name, "--telegram"])

      assert_file(
        "#{@app_name}/lib/#{@app_name}_bot/endpoint.ex",
        "poller Marvin.Telegram.Poller"
      )

      assert_file("#{@app_name}/config/config.exs", "config :nadia, token: \"your-bot-token\"")
    end)
  end

  test "new with invalid args" do
    assert_raise Mix.Error, ~r/Application name must start with a letter and /, fn ->
      Mix.Tasks.Mvn.New.run(["0_app"])
    end

    assert_raise Mix.Error, ~r/Application name must start with a letter and /, fn ->
      Mix.Tasks.Mvn.New.run(["valid", "--app", "0_app"])
    end

    assert_raise Mix.Error, ~r/Module name must be a valid Elixir alias/, fn ->
      Mix.Tasks.Mvn.New.run(["valid", "--module", "not.valid"])
    end

    assert_raise Mix.Error, ~r/Module name \w+ is already taken/, fn ->
      Mix.Tasks.Mvn.New.run(["string"])
    end

    assert_raise Mix.Error, ~r/Module name \w+ is already taken/, fn ->
      Mix.Tasks.Mvn.New.run(["valid", "--app", "mix"])
    end

    assert_raise Mix.Error, ~r/Module name \w+ is already taken/, fn ->
      Mix.Tasks.Mvn.New.run(["valid", "--module", "String"])
    end
  end

  test "invalid options" do
    assert_raise Mix.Error, ~r/Invalid option: -a/, fn ->
      Mix.Tasks.Mvn.New.run(["valid", "-app", "app_name"])
    end
  end

  test "new without args", %{test: test} do
    in_tmp(test, fn ->
      assert capture_io(fn -> Mix.Tasks.Mvn.New.run([]) end) =~ "Creates a new Marvin project."
    end)
  end
end
