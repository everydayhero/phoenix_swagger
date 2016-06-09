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
  def run([output_file]), do: run(output_file)
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
    base_swagger_map
    |> collect_info
    |> collect_host
    |> collect_paths
    |> Poison.encode!(pretty: true)
  end

  defp base_swagger_map, do: %{swagger: "2.0"}

  defp collect_info(swagger_map) do
    info = if function_exported?(Project.get, :swagger_info, 0) do
      Map.merge(Project.get.swagger_info, default_info_section)
    else
      default_info_section()
    end

    Map.put_new(swagger_map, :info, info)
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

  defp collect_paths(swagger_map) do
    api_routes = router_module.__routes__

    paths = List.foldl(api_routes, %{},
      fn (route, acc) ->
        {controller, swagger_output_function} = find_swagger_output_function(route)

        path = format_path(route.path)

        if function_exported?(controller, swagger_output_function, 0) do
          %{^path => swagger_action} = apply(controller, swagger_output_function, [])

          Map.merge(acc, %{path => swagger_action}, fn _, m1, m2 -> Map.merge(m1, m2) end)
        else
          acc
        end
      end)

    Map.put_new(swagger_map, :paths, paths)
  end

  defp find_swagger_output_function(route_map) do
    controller = Module.concat([:Elixir | Module.split(route_map.plug)])
    swagger_fun = "swagger_#{to_string(route_map.opts)}" |> String.to_atom

    if Code.ensure_loaded?(controller) == false do
      raise "Error: #{controller} module didn't load."
    else
      {controller, swagger_fun}
    end
  end

  defp format_path(path) do
    case String.split(path, ":") do
      [_] -> path
      path_list ->
        List.foldl(path_list, "", fn(p, acc) ->
          if not String.starts_with?(p, "/") do
            [parameter | rest] = String.split(p, "/")
            parameter = acc <> "{" <> parameter <> "}"
            case rest do
              [] -> parameter
              _ ->  parameter <> "/" <> Enum.join(rest, "/")
            end
          else
            acc <> p
          end
        end)
    end
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

  defp default_info_section do
    %{
      title: @default_title,
      version: @default_version,
    }
  end

end
