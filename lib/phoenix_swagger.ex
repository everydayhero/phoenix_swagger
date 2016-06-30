defmodule PhoenixSwagger do
  @moduledoc "Generates functions from the PhoenixSwagger DSL into Swagger maps"
  alias PhoenixSwagger.Util

  defmacro swagger_path(action, expr) do
    body = Util.pipeline_body(expr)
    fun_name = "swagger_path_#{action}" |> String.to_atom
    quote do
      def unquote(fun_name)() do
        import PhoenixSwagger.Path
        alias PhoenixSwagger.Schema
        unquote(body)
        |> operation_id("#{__MODULE__}.#{unquote(action)}" |> String.replace_prefix("Elixir.",""))
        |> nest
        |> Util.to_json
      end
    end
  end

  defmacro swagger_definitions([do: {:__block__, [], exprs}]) do
    quote do
      def swagger_definitions do
        require PhoenixSwagger.JsonApi
        alias PhoenixSwagger.JsonApi
        alias PhoenixSwagger.Schema
        import PhoenixSwagger.Schema
        unquote(exprs) |> List.flatten |> Enum.into(%{}) |> Util.to_json
      end
    end
  end
  defmacro swagger_definitions([do: expr]) do
    quote do
      def swagger_definitions do
        require PhoenixSwagger.JsonApi
        alias PhoenixSwagger.JsonApi
        alias PhoenixSwagger.Schema
        import PhoenixSwagger.Schema
        unquote(expr) |> Enum.into(%{}) |> Util.to_json
      end
    end
  end
end
