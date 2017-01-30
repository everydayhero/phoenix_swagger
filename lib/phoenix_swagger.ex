defmodule PhoenixSwagger do
  @moduledoc "Generates functions from the PhoenixSwagger DSL into Swagger maps"
  alias PhoenixSwagger.Util
  alias PhoenixSwagger.Path
  alias PhoenixSwagger.Path.PathObject

  @doc """
  Swagger operations (aka "paths") are defined inside a `swagger_path` block.

  Within the do-end block, the DSL provided by the `PhoenixSwagger.Path` module can be used.
  The DSL always starts with one of the `get`, `put`, `post`, `delete`, `head`, `options` functions,
  followed by any functions with first argument being a `PhoenixSwagger.Path.PathObject` struct.

  ## Example
      defmodule ExampleController do
        use ExampleApp.Web, :controller
        import PhoenixSwagger

        swagger_path :index do
          get "/users"
          summary "Get users"
          description "Get users, filtering by account ID"
          parameter :query, :id, :integer, "account id", required: true
          response 200, "Description", :Users
          tag "users"
        end

        def index(conn, _params) do
          posts = Repo.all(Post)
          render(conn, "index.json", posts: posts)
        end
      end
  """
  defmacro swagger_path(action, expr) do
    body = Util.pipeline_body(expr)
    fun_name = "swagger_path_#{action}" |> String.to_atom

    quote do
      def unquote(fun_name)() do
        import PhoenixSwagger.Path
        alias PhoenixSwagger.Schema

        unquote(body)
        |> PhoenixSwagger.ensure_operation_id(__MODULE__, unquote(action))
        |> nest
        |> Util.to_json
      end
    end
  end

  @doc false
  def ensure_operation_id(path = %PathObject{operation: %{operationId: ""}}, module, action) do
    Path.operation_id(path, String.replace_prefix("#{module}.#{action}", "Elixir.",""))
  end
  def ensure_operation_id(path, _module, _action), do: path

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


  @doc """
  This macro accepts a block where the schema is defined by listing the properties using a DSL.
  Defining a property for the schema takes 3 required parameters and one optional parameter.

  The first parameter is the name of the property.
  The second parameter is the property type, either a simple type like :string, or a %Schema{} struct.
  The third parameter is the description of the property.
  The fourth optional parameter is an optional list of parameters that is passed to the PhoenixSwagger.Schema.

  All these values are taken and placed into a PhoenixSwagger.Schema struct.

  The PhoenixSwagger.Schema struct is returned from a `schema/0` function that is provided by this macro.

  Example:
    swagger_schema do
      full_name, :string, "Full name"
      title, :string, "Title", required: true
      genre, :string, "Genre", enum: [:scifi, :horror, :drama, :comedy]
      birthday, :datetime, "Birthday", format: :datetime
    end
  """
  defmacro swagger_schema(properties_block) do
    properties = case properties_block do
      [do: {:__block__, _, info}] -> info
      [do: info] -> [info]
    end

    model = %PhoenixSwagger.Schema{type: :object}

    body =
      properties
      |> Enum.map(fn {name, line, args} -> {:property, line, [name | args]} end)
      |> Enum.reduce(Macro.escape(model), fn next, pipeline ->
          quote do
            unquote(pipeline) |> unquote(next)
          end
        end)

    quote do
      def schema do
        alias PhoenixSwagger.Schema
        import PhoenixSwagger.Schema
        unquote(body)
      end
    end
  end
end
