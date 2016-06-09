defmodule PhoenixSwagger do
  defmacro __using__(_) do
    quote do
      import PhoenixSwagger
    end
  end

  def get(path) do
    %{
      path => %{
        "get" => %{
          "summary" => "",
          "description" => "",
          "parameters" => [],
          "responses" => %{}
        }
      }
    }
  end

  defp deconstruct(swagger) do
    path = Map.keys(swagger) |> List.first
    verb = Map.keys(swagger[path]) |> List.first
    {path, verb, swagger[path][verb]}
  end

  def summary(swagger, summary) do
    {path, verb, _} = deconstruct(swagger)
    put_in(swagger, [path, verb, "summary"], summary)
  end

  def description(swagger, desc) do
    {path, verb, _} = deconstruct(swagger)
    put_in(swagger, [path, verb, "description"], desc)
  end

  def parameter(swagger, location, name, type, desc, required \\ nil) do
    param = %{
      "in" => location |> Atom.to_string,
      "name" => name |> Atom.to_string,
      "type" => type |> Atom.to_string,
      "description" => desc,
      "required" => if (required) do true else false end
    }
    {path, verb, operation} = deconstruct(swagger)
    parameters = operation["parameters"]
    put_in(swagger, [path, verb, "parameters"], parameters ++ [param])
  end

  def responses(swagger, status, desc) do
    {path, verb, _operation} = deconstruct(swagger)
    put_in(swagger, [path, verb, "responses", status |> to_string], %{"description" => desc})
  end
  def responses(swagger, status, desc, ref: references) do
    {path, verb, _operation} = deconstruct(swagger)
    put_in(
      swagger,
      [path, verb, "responses", status |> to_string],
      %{
        "description" => desc,
        "schema" => %{"$ref" => references}
      }
    )
  end

  defmacro swagger_model(action, expr) do
    body = pipeline_body(expr)
    fun_name = "swagger_#{action}" |> String.to_atom
    quote do
      def unquote(fun_name)() do
        unquote(body)
      end
    end
  end

  def pipeline_body([do: {:__block__, _, [head | tail]}]) do
    Enum.reduce(tail, head, fn next, pipeline ->
      quote do: unquote(pipeline) |> unquote(next)
    end)
  end
  def pipeline_body([do: expr]), do: expr

end
