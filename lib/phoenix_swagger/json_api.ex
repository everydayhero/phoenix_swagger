defmodule PhoenixSwagger.JsonApi do
  alias PhoenixSwagger.Util
  alias PhoenixSwagger.Schema

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

  defmacro resource(name, plural, expr) do
    quote do
      import unquote(__MODULE__)
      [
        {
          (unquote(name) |> to_string),
          %Schema {
            type: :object,
            properties: %{
              attributes: %Schema{
                type: :object,
                properties: %{}
              }
            }
          }
          |> unquote(Util.pipeline_body(expr))
        },
        {
          (unquote(plural) |> to_string),
          page(unquote(name))
        }
      ]
    end
  end

  def description(model = %Schema{}, desc) do
    %{model | description: desc}
  end

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

  def attribute(model = %Schema{}, name, type, description) do
    put_in model.properties.attributes.properties[name],
     %Schema {
       type: type,
       description: description
     }
  end
end
