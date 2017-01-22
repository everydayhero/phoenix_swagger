defmodule PhoenixSwagger.SchemaDefinition do
  @moduledoc """
  Provides a DSL to define Swagger Schemas outside of `swagger_definitions/1`. This separates the definition of a schema
  from the placement inside of swagger.

  # Example:

  defmodule Example.Schemas.Book do
    use PhoenixSwagger.SchemaDefinition

    swagger_schema do
      title :string, "Title", required: true
      author :string, "Author", required: true
    end
  end
  """
  alias PhoenixSwagger.Schema

  defmacro __using__(_opts) do
    quote do
      import PhoenixSwagger.SchemaDefinition
    end
  end

  @doc """
  This macro accepts a block where the schema is defined by listing the properties using a DSL.
  Defining a property for the schema takes 2 required parameters and one optional parameter.

  The first parameter is the name of the property.
  The second parameter is the property type.
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

    properties = Enum.map(properties, &map_properties/1)

    required = for {key, required, _} <- properties, required == true, do: key
    properties = for {key, _, schema} <- properties, into: %{}, do: {key, schema}

    quote do
      def schema do
        %Schema{
          type: :object,
          required: unquote(Macro.escape(required)),
          properties: unquote(Macro.escape(properties))
        }
      end
    end
  end

  defp map_properties({name, _, details}) do
    [type, description, opts] = case details do
      [type, description] -> [type, description, []]
      [type, description, opts] -> [type, description, opts]
    end

    {
      name,
      opts[:required],
      Schema.__struct__([type: type, description: description] ++ Keyword.delete(opts, :required))
    }
  end
end