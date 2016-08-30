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

  @doc """
  Schemas for swagger models (aka "definitions") are defined inside a `swagger_definitions` block.

  The body of the do-end block should contain a keyword list of `%Schema{}` structs.
  These can be created directly, as in the first example below,
   or using the json-api DSL as in the second example.

  ## Example 1: Creating schemas directly

      defmodule Example do
        import PhoenixSwagger

        swagger_definitions do
          [
            user: %Schema {
              type: :object,
              properties: %{
                name: %Schema { type: :string, description: "Full Name" }
              }
            },
            shopping_cart: %Schema {
              type: :object,
              properties: %{
                contents: %Schema { type: :array, items: %Schema { type: :string } }
              }
            }
          ]
        end
      end

  ## Example 2: Using the JSON-API DSL

      defmodule Example2 do
        import PhoenixSwagger

        swagger_definitions do
          JsonApi.resource(:Product, :Products) do
            description "A product from the catalog"
            attributes do
              title :string, "The product title", required: true
              updated_at :string, "Last update timestamp UTC", format: "ISO-8601"
            end
          end
        end
      end
  """
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
