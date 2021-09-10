defmodule Mix.Tasks.Mvn.Generator do
  alias Mix.Tasks.Mvn.Project

  import Mix.Generator

  @marvin_version Version.parse!(Mix.Project.config()[:version])

  @callback prepare_project(Project.t()) :: Project.t()
  @callback generate(Project.t()) :: Project.t()

  defmacro __using__(_env) do
    quote do
      @behaviour unquote(__MODULE__)
      import Mix.Generator
      import unquote(__MODULE__)
      Module.register_attribute(__MODULE__, :templates, accumulate: true)
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(env) do
    root = Path.expand("../../../priv/templates", __DIR__)

    templates_ast =
      for {name, mappings} <- Module.get_attribute(env.module, :templates) do
        for {format, source, _, _} <- mappings, format != :keep do
          path = Path.join(root, source)

          if format in [:eex] do
            compiled = EEx.compile_file(path)

            quote do
              @external_resource unquote(path)
              @file unquote(path)
              def render(unquote(name), unquote(source), var!(assigns))
                  when is_list(var!(assigns)),
                  do: unquote(compiled)
            end
          else
            quote do
              @external_resource unquote(path)
              def render(unquote(name), unquote(source), _assigns), do: unquote(File.read!(path))
            end
          end
        end
      end

    quote do
      unquote(templates_ast)
      def template_files(name), do: Keyword.fetch!(@templates, name)
    end
  end

  defmacro template(name, mappings) do
    quote do
      @templates {unquote(name), unquote(mappings)}
    end
  end

  def put_binding(%Project{opts: opts} = project) do
    telegram = Keyword.get(opts, :telegram, false)

    marvin_path = marvin_path(project)

    version = @marvin_version

    binding = [
      app_name: project.app,
      app_module: inspect(project.app_mod),
      root_app_name: project.root_app,
      root_app_module: inspect(project.root_mod),
      lib_bot_name: project.lib_bot_name,
      bot_app_name: project.bot_app,
      endpoint_module: inspect(Module.concat(project.bot_namespace, Endpoint)),
      bot_namespace: inspect(project.bot_namespace),
      marvin_dep: marvin_dep(marvin_path, version),
      telegram: telegram
    ]

    %Project{project | binding: binding}
  end

  defp marvin_path(%Project{}) do
    "deps/marvin"
  end

  defp marvin_dep("deps/marvin", version) do
    ~s[{:marvin, "~> #{version}"}]
  end

  defp marvin_dep(path, _version) do
    ~s[{:marvin, path: #{inspect(path)}}]
  end

  def copy_from(%Project{} = project, mod, name) when is_atom(name) do
    mapping = mod.template_files(name)

    for {format, source, project_location, target_path} <- mapping do
      target = Project.join_path(project, project_location, target_path)

      case format do
        :keep ->
          File.mkdir_p!(target)

        :eex ->
          contents = mod.render(name, source, project.binding)
          create_file(target, contents)
      end
    end
  end
end
