defmodule PhoenixSwagger.JsonApi do
  @moduledoc """
  This module defines a DSL for defining swagger definitions in a JSON-API conformant format.s

  ## Examples
    import PhoenixSwagger

    swagger_definitions do
      JsonApi.resource(:User, :Users) do
        description "A user that may have one or more supporter pages."
        attributes do
          user_updated_at :string, "Last update timestamp UTC", format: "ISO-8601"
          user_created_at :string, "First created timestamp UTC"
          street_address :string, "Street address"
        end
      end
    end
  """

  alias PhoenixSwagger.Util
  alias PhoenixSwagger.Schema

  @doc """
  Defines a schema for a paged list of results.
  This is used automatically from the JsonApi.resource macro is used.
  """
  def page(resource) do
    %Schema {
      type: :object,
      description: "A page of [#{resource}](##{resource |> to_string |> String.downcase}) results",
      properties: %{
        meta: %Schema {
          type: :object,
          properties: %{
            "total-pages": %Schema {
              type: :integer,
              description: "The total number of pages available"
            }
          },
          required: [:"total-pages"]
        },
        links: %Schema {
          type:  :object,
          properties: %{
            self: %Schema {
              type:  :string,
              description:  "Link to this page of results"
            },
            prev: %Schema {
              type:  :string,
              description:  "Link to the previous page of results"
            },
            next: %Schema {
              type:  :string,
              description:  "Link to the next page of results"
            },
            last: %Schema {
              type:  :string,
              description:  "Link to the last page of results"
            },
            first: %Schema {
              type:  :string,
              description:  "Link to the first page of results"
            }
          },
          required:  [:self, :prev, :next, :last, :first]
        },
        data: %Schema {
          type:  :array,
          description:  "Content with [#{resource}](##{resource |> to_string |> String.downcase}) objects",
          items: %Schema {
            "$ref": "#/definitions/#{resource}"
          }
        }
      },
      required:  [:meta, :links, :data]
    }
  end

  def single(resource) do
    %Schema {
      type: :object,
      description: "A JSON-API document with a single [#{resource}](##{resource |> to_string |> String.downcase}) resource",
      properties: %{
        links: %Schema {
          type:  :object,
          properties: %{
            self: %Schema {
              type:  :string,
              description:  "the link that generated the current response document."
            }
          },
          required:  [:self]
        },
        data: %Schema {
          "$ref": "#/definitions/#{resource}"
        },
        included: %Schema {
          type: :array,
          description: "Included resources"
        }
      },
      required:  [:links, :data]
    }
  end

  @doc """
  Defines schemas for a JSON-API resource, and a paginated list of results.
  """
  defmacro resource(name, plural, expr) do
    resource_name = "#{name}Resource"
    quote do
      import unquote(__MODULE__)
      [
        {
          unquote(resource_name),
          %Schema {
            type: :object,
            properties: %{
              type: %Schema{type: :string, description: "The JSON-API resource type"},
              id: %Schema{type: :string, description: "The JSON-API resource ID"},
              relationships: %Schema{type: :object, properties: %{}},
              links: %Schema{type: :object, properties: %{}},
              attributes: %Schema{
                type: :object,
                properties: %{}
              }
            }
          }
          |> unquote(Util.pipeline_body(expr))
        },
        {
          (unquote(name) |> to_string),
          single(unquote(resource_name))
        },
        {
          (unquote(plural) |> to_string),
          page(unquote(resource_name))
        }
      ]
    end
  end

  @doc """
  Defines a block of attributes for a JSON-API resource.
  Within this block, each function call will be translated into a
  call to the :attribute function.

  ## Example

  description("A User")
  attributes do
    name :string, "Full name of the user", required: true
    dateOfBirth :string, "Date of Birth", format: "ISO-8601", required: false
  end

  translates to:
  description("A User")
  |> attribute(:name, :string, "Full name of the user", required: true)
  |> attribute(:dateOfBirth, :string, "Date of Birth", format: "ISO-8601", required: false)
  """
  defmacro attributes(model, [do: {:__block__, _, attrs}]) do
    attrs
    |> Enum.map(fn {name, line, args} ->
         {:attribute, line, [name | args]}
       end)
    |> Enum.reduce(model, fn next, pipeline ->
         quote do
           unquote(pipeline) |> unquote(next)
         end
       end)
  end

  @doc """
  Defines an attribute in a JSON-API schema.

  Name, type and description are accepted as positional arguments, but any other
  schema properties can be set through the trailing keyword arguments list.
  As a convenience, required: true can be passed in the keyword args, causing the
   name of this attribute to be added to the "required" list of the attributes schema.

  """
  def attribute(model = %Schema{}, name, type, description, opts \\ []) do
    schema = opts
      |> Keyword.drop([:required])
      |> Enum.reduce(
          %Schema{type: type, description: description},
          fn {k, v}, acc -> %{acc | k => v} end)

    model = put_in model.properties.attributes.properties[name], schema

    required = case {model.properties.attributes.required, opts[:required]} do
      {nil, true} -> [name]
      {r, true} -> r ++ [name]
      {r, _} -> r
    end

    put_in model.properties.attributes.required, required
  end

  @doc """
  Defines a link with name and description
  """
  def link(model = %Schema{}, name, description) do
    put_in(
      model.properties.links.properties[name],
      %Schema{type: :string, description: description}
    )
  end

  @doc """
  Defines a relatioship
  """
  def relationship(model = %Schema{}, name) do
    put_in(
      model.properties.relationships.properties[name],
      %Schema{
        type: :object,
        properties: %{
          links: %Schema{
            type: :object,
            properties: %{
              self: %Schema{type: :string, description: "Relationship link for #{name}"},
              related: %Schema{type: :string, description: "Related #{name} link"} 
            }
          },
          data: %Schema{
            type: :object,
            properties: %{
              id: %Schema{type: :string, description: "Related #{name} resource id"},
              type: %Schema{type: :string, description: "Type of related #{name} resource"}
            }
          }
        }
      }
    )
  end
end
