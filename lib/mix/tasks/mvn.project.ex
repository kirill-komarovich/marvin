defmodule Mix.Tasks.Mvn.Project do
  alias Mix.Tasks.Mvn.Project

  defstruct base_path: nil,
            app: nil,
            app_mod: nil,
            app_path: nil,
            lib_bot_name: nil,
            root_app: nil,
            root_mod: nil,
            project_path: nil,
            bot_app: nil,
            bot_namespace: nil,
            bot_path: nil,
            opts: :unset,
            binding: []

  def new(project_path, opts) do
    project_path = Path.expand(project_path)
    app = opts[:app] || Path.basename(project_path)
    app_mod = Module.concat([opts[:module] || Macro.camelize(app)])

    %Project{
      base_path: project_path,
      app: app,
      app_mod: app_mod,
      root_app: app,
      root_mod: app_mod,
      opts: opts
    }
  end

  def join_path(%Project{} = project, location, path) when location in [:project, :app, :bot] do
    project
    |> Map.fetch!(:"#{location}_path")
    |> Path.join(path)
    |> expand_path_with_bindings(project)
  end

  defp expand_path_with_bindings(path, %Project{} = project) do
    Regex.replace(Regex.recompile!(~r/:[a-zA-Z0-9_]+/), path, fn ":" <> key, _ ->
      project |> Map.fetch!(:"#{key}") |> to_string()
    end)
  end
end
