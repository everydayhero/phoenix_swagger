defmodule Mix.Tasks.Phoenix.Swagger.Generate do
  use Mix.Task
  alias Mix.Project

  @shortdoc "Generates swagger.json file based on controller defintions"

  @moduledoc """
  Generates swagger.json file based on controller definitions

  Usage:

      mix phoenix.swagger.generate

      mix phoenix.swagger.generate ../swagger.json
  """

  @default_port 4000
  @default_title "<Untitled>"
  @default_version "0.0.1"

  @app_path Project.load_paths
    |> Enum.at(0)
    |> String.split("_build")
    |> Enum.at(0)
  @swagger_file_name "swagger.json"
  @swagger_file_path @app_path <> @swagger_file_name

  def run([]), do: run(@swagger_file_path)
  def run([output_file | _ignored]), do: run(output_file)
  def run(output_file) when is_binary(output_file) do
    Code.append_path(ebin)
    File.write(output_file, swagger_documentation)
    Code.delete_path(ebin)
    IO.puts "Documentation generated to #{output_file}"
  end
  def run(_) do
    IO.puts """
    Usage: mix phoenix.swagger.generate [FILE]

    With no FILE, default swagger file - #{@swagger_file_path}.
    """
  end

  defp swagger_documentation do
    collect_outline
    |> collect_host
    |> collect_paths
    |> collect_definitions
    |> Poison.encode!(pretty: true)
  end

  defp collect_outline() do
    if function_exported?(Project.get, :swagger_spec, 0) do
      Project.get.swagger_spec
    else
      default_outline()
    end
  end

  defp collect_host(swagger_map) do
    endpoint_config = Application.get_env(app_name, Module.concat([app_module, :Endpoint]))
    [{:host, host}] = Keyword.get(endpoint_config, :url, [{:host, "localhost"}])
    [{:port, port}] = Keyword.get(endpoint_config, :http, [{:port, @default_port}])
    swagger_map = Map.put_new(swagger_map, :host, host <> ":" <> to_string(port))

    case endpoint_config[:https] do
      nil ->
        swagger_map
      _ ->
        Map.put_new(swagger_map, :schemes, ["https", "http"])
    end
  end

  defp collect_definitions(swagger_map) do
    router_module.__routes__
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

  defp collect_paths(swagger_map) do
    router_module.__routes__
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

  defp router_module do
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
