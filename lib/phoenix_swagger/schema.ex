defmodule PhoenixSwagger.Schema do
  @moduledoc """
  Struct and helpers for swagger schema
  """

  alias PhoenixSwagger.Schema

  defstruct(
    '$ref': nil,
    format: nil,
    title: nil,
    description: nil,
    default: nil,
    multipleOf: nil,
    maximum: nil,
    exclusiveMaximum: nil,
    minimum: nil,
    exclusiveMinimum: nil,
    maxLength: nil,
    minLength: nil,
    pattern: nil,
    maxItems: nil,
    minItems: nil,
    uniqueItems: nil,
    enum: nil,
    maxProperties: nil,
    minProperties: nil,
    required: nil,
    enum: nil,
    type: nil,
    items: nil,
    allOf: nil,
    properties: nil,
    additionalProperties: nil)

  @doc """
  Construct a schema reference, using name of definition in this swagger document,
    or a complete path.
  """
  def ref(name) when is_atom(name) do
    %Schema{'$ref': "#/definitions/#{name}"}
  end
  def ref(path) when is_binary(path) do
    %Schema{'$ref': path}
  end

  @doc """
  Construct an array schema, where the array items schema is a ref to the given name.

  Schema.array(:User) == %Schema{type: :array, items: Schema.ref(:User)}
  """
  def array(name) when is_atom(name) do
    %Schema{
      type: :array,
      items: ref(name)
    }
  end

  @doc """
  Sets the description for the schema
  """
  def description(model = %Schema{}, desc) do
    %{model | description: desc}
  end

  @doc """
  Sets a property of the Schema
  """
  def property(model, name, type, description, opts \\ [])
  def property(model = %Schema{}, name, type, description, opts) when is_atom(type) do
    property(model, name, %Schema{type: type}, description, opts)
  end
  def property(model = %Schema{}, name, type = %Schema{}, description, opts) do
    required = case {model.required, opts[:required]} do
      {nil, true} -> [name]
      {r, true} -> r ++ [name]
      {r, _} -> r
    end

    property_schema = struct!(type, Keyword.delete(opts, :required) ++ [description: description])
    properties = (model.properties || %{}) |> Map.put(name, property_schema)

    %{model | properties: properties, required: required}
  end

  @doc """
  This macro accepts a block where the schema is defined by listing the properties using a DSL.
  Defining a property for the schema takes 2 required parameters and one optional parameter.

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

    model = %Schema{type: :object}

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
        unquote(body)
      end
    end
  end
end
