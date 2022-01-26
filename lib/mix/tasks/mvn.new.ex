defmodule Mix.Tasks.Mvn.New do
  @moduledoc """
  Creates a new Marvin project.
  It expects the path of the project as an argument.

    $ mix mvn.new PATH [--module MODULE] [--app APP]

  A project at the given PATH will be created. The
  application name and module name will be retrieved
  from the path, unless `--module` or `--app` is given.

  ## Options

    * `--app` - the name of the OTP application

    * `--module` - the name of the base module in
      the generated skeleton

    * `--telegram` - adds telegram poller

  ## Examples

      $ mix mvn.new hello_world

  Is equivalent to:

      $ mix mvn.new hello_world --module HelloWorld

  Or with telegram poller:

      $ mix phx.new ~/some_path/hello_world --telegram

  """
  alias Mix.Tasks.Mvn.Project
  alias Mix.Tasks.Mvn.Generator

  use Mix.Task
  use Generator

  @switches [app: :string, module: :string, bot_module: :string, telegram: :boolean]

  template(:new, [
    {:eex, "app/config/config.exs", :project, "config/config.exs"},
    {:eex, "app/lib/app_name/application.ex", :project, "lib/:app/application.ex"},
    {:eex, "app/lib/app_name.ex", :project, "lib/:app.ex"},
    {:eex, "mvn_bot/handlers/hello_handler.ex", :project,
     "lib/:lib_bot_name/handlers/hello_handler.ex"},
    {:eex, "mvn_bot/handlers/unknown_handler.ex", :project,
     "lib/:lib_bot_name/handlers/unknown_handler.ex"},
    {:eex, "mvn_bot/endpoint.ex", :project, "lib/:lib_bot_name/endpoint.ex"},
    {:eex, "mvn_bot/matcher.ex", :project, "lib/:lib_bot_name/matcher.ex"},
    {:eex, "mvn_bot/telemetry.ex", :project, "lib/:lib_bot_name/telemetry.ex"},
    {:eex, "app/lib/app_name_bot.ex", :project, "lib/:lib_bot_name.ex"},
    {:eex, "app/mix.exs", :project, "mix.exs"},
    {:eex, "app/README.md", :project, "README.md"},
    {:eex, "app/formatter.exs", :project, ".formatter.exs"},
    {:eex, "app/gitignore", :project, ".gitignore"},
    {:eex, "app/test/test_helper.exs", :project, "test/test_helper.exs"},
    {:eex, "app/test/support/event_case.ex", :project, "test/support/event_case.ex"}
  ])

  @impl true
  def run(args) do
    case parse_opts(args) do
      {_opts, []} -> Mix.Tasks.Help.run(["mvn.new"])
      {opts, [base_path | _]} -> generate(base_path, :project_path, opts)
    end
  end

  defp parse_opts(args) do
    case OptionParser.parse(args, strict: @switches) do
      {opts, args, []} ->
        {opts, args}

      {_opts, _args, [switch | _]} ->
        Mix.raise("Invalid option: " <> switch_to_string(switch))
    end
  end

  defp switch_to_string({name, nil}), do: name
  defp switch_to_string({name, val}), do: name <> "=" <> val

  defp generate(base_path, path, opts) do
    base_path
    |> Project.new(opts)
    |> prepare_project()
    |> Generator.put_binding()
    |> Project.Validator.validate(path)
    |> generate
  end

  @impl true
  def prepare_project(%Project{app: app} = project) when not is_nil(app) do
    %Project{project | project_path: project.base_path}
    |> put_app()
    |> put_root_app()
    |> put_bot_app()
  end

  defp put_app(%Project{base_path: base_path} = project) do
    %Project{project | app_path: base_path}
  end

  defp put_root_app(%Project{app: app, opts: opts} = project) do
    %Project{
      project
      | root_app: app,
        root_mod: Module.concat([opts[:module] || Macro.camelize(app)])
    }
  end

  defp put_bot_app(%Project{app: app} = project) do
    %Project{
      project
      | bot_app: app,
        lib_bot_name: "#{app}_bot",
        bot_namespace: Module.concat(["#{project.root_mod}Bot"]),
        bot_path: project.project_path
    }
  end

  @impl true
  def generate(%Project{} = project) do
    copy_from(project, __MODULE__, :new)

    project
  end
end
