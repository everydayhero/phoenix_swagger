defmodule PhoenixSwagger.PathTest do
  use ExUnit.Case
  import PhoenixSwagger

  doctest PhoenixSwagger.Path

  swagger_path :index do
    get("/api/v1/users")
    summary("Query for users")
    description("Query for users with paging and filtering")
    produces "application/json"
    tag "Users"
    paging()
    parameter("filter[gender]", "query", "string", "Gender of the user", required: true)
    response(200, "OK", Schema.ref(:Users))
    response(400, "Client Error")
  end

   test "produces expected swagger json" do
    assert swagger_path_index == %{
      "/api/v1/users" => %{
        "get" => %{
          "consumes" => [],
          "produces" => ["application/json"],
          "tags" => ["Users"],
          "operationId" => "PhoenixSwagger.PathTest.index",
          "summary" => "Query for users",
          "description" => "Query for users with paging and filtering",
          "parameters" => [
            %{
              "description" => "Number of elements per page",
              "in" => "query",
              "name" => "page[size]",
              "required" => false,
              "type" => "integer",
              "minimum" => 1
            },
            %{
              "description" => "Number of the page",
              "in" => "query",
              "name" => "page[number]",
              "required" => false,
              "type" => "integer",
              "minimum" => 1
            },
            %{
              "description" => "Gender of the user",
              "in" => "query",
              "name" => "filter[gender]",
              "required" => true,
              "type" => "string"
            }
          ],
          "responses" => %{
            "200" => %{
              "description" => "OK",
              "schema" =>  %{
                "$ref" => "#/definitions/Users"
              }
            },
            "400" => %{
              "description" => "Client Error"
            }
          }
        }
      }
    }
  end
end
