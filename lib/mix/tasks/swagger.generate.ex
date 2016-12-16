defmodule Mix.Tasks.Phoenix.Swagger.Generate do
  use Mix.Task
  alias Mix.Project

  @shortdoc "Generates swagger.json file based on controller defintions"
  @recursive true

  @moduledoc """
  Generates swagger.json file based on controller definitions

  Usage:

      mix phoenix.swagger.generate

      mix phoenix.swagger.generate --output ../swagger.json

      mix phoenix.swagger.generate --output ../swagger.json --router MyApp.Router
  """

  @default_port 4000
  @default_title "<Untitled>"
  @default_version "0.0.1"

  @app_path Project.load_paths
    |> Enum.at(0)
    |> String.split("_build")
    |> Enum.at(0)
  @default_swagger_file_path @app_path <> "swagger.json"

  def run(args) do
    Mix.Task.reenable("phoenix.swagger.generate")
    Code.append_path(ebin)
    {switches, _params, _unknown} = OptionParser.parse(
      args,
      switches: [output: :string, router: :string, help: :boolean],
      aliases: [o: :output, r: :router, h: :help])

    if (Keyword.get(switches, :help)) do
      usage
    else
      output_file = Keyword.get(switches, :output, @default_swagger_file_path)
      router = load_router(switches)
      File.write(output_file, swagger_documentation(router))
      IO.puts "Documentation generated to #{output_file}"
    end
  end

  defp usage do
    IO.puts """
    Usage: mix phoenix.swagger.generate --output FILE --router ROUTER

    With no FILE, default swagger file - #{@default_swagger_file_path}
    With no ROUTER, defaults to - <Application>.Router
    """
  end

  defp load_router(switches) do
    {:module, router} =
      switches
      |> Keyword.get(:router, default_router_module)
      |> List.wrap
      |> Module.concat()
      |> Code.ensure_loaded()

    router
  end

  defp swagger_documentation(router) do
    router
    |> collect_outline
    |> collect_host
    |> collect_paths(router)
    |> collect_definitions(router)
    |> Poison.encode!(pretty: true)
  end

  defp collect_outline(router) do
    if function_exported?(router, :swagger_spec, 0) do
      router.swagger_spec
    else
      default_outline()
    end
  end

  defp collect_host(swagger_map) do
    endpoint_config = Application.get_env(app_name, Module.concat([app_module, :Endpoint]))

    url = Keyword.get(endpoint_config, :url, [host: "localhost", port: @default_port])
    host = Keyword.get(url, :host, "localhost")
    port = Keyword.get(url, :port, @default_port)
    swagger_map = Map.put_new(swagger_map, :host, "#{host}:#{port}")

    case endpoint_config[:https] do
      nil ->
        swagger_map
      _ ->
        Map.put_new(swagger_map, :schemes, ["https", "http"])
    end
  end

  defp collect_definitions(swagger_map, router) do
    router.__routes__
    |> Enum.map(&find_controller/1)
    |> Enum.uniq()
    |> Enum.filter(&function_exported?(&1, :swagger_definitions, 0))
    |> Enum.map(&apply(&1, :swagger_definitions, []))
    |> Enum.reduce(swagger_map, &merge_definitions/2)
  end

  defp find_controller(route_map) do
    Module.concat([:Elixir | Module.split(route_map.plug)])
  end

  defp merge_definitions(definitions, swagger_map = %{definitions: existing}) do
    %{swagger_map | definitions: Map.merge(existing, definitions)}
  end

  defp collect_paths(swagger_map, router) do
    router.__routes__
    |> Enum.map(&find_swagger_path_function/1)
    |> Enum.filter(&controller_function_exported/1)
    |> Enum.map(&get_swagger_path/1)
    |> Enum.reduce(swagger_map, &merge_paths/2)
  end

  defp find_swagger_path_function(route_map) do
    controller = find_controller(route_map)
    swagger_fun = "swagger_path_#{to_string(route_map.opts)}" |> String.to_atom

    unless Code.ensure_loaded?(controller) do
      raise "Error: #{controller} module didn't load."
    end

    %{
      controller: controller,
      swagger_fun: swagger_fun,
      path: format_path(route_map.path)
    }
  end

  defp format_path(path) do
    Regex.replace(~r/:([^\/]+)/, path, "{\\1}")
  end

  defp controller_function_exported(%{controller: controller, swagger_fun: fun}) do
    function_exported?(controller, fun, 0)
  end

  defp get_swagger_path(%{controller: controller, swagger_fun: fun, path: path}) do
    %{^path => _action} = apply(controller, fun, [])
  end

  defp merge_paths(path, swagger_map) do
    paths = Map.merge(swagger_map.paths, path, &merge_conflicts/3)
    %{swagger_map | paths: paths}
  end

  defp merge_conflicts(_key, value1, value2) do
    Map.merge(value1, value2)
  end

  defp app_module do
    Project.get.application[:mod]
    |> elem(0)
  end

  defp app_name do
    Project.get.project[:app]
  end

  defp default_router_module do
    Module.concat([app_module, :Router])
  end

  defp ebin do
    "#{@app_path}_build/#{Mix.env}/lib/#{app_name}/ebin"
  end

  defp default_outline do
    %{
      swagger: "2.0",
      info: %{
        title: @default_title,
        version: @default_version,
      }
    }
  end
end
