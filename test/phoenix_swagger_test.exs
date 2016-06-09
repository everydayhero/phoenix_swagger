defmodule PhoenixSwaggerTest do
  use ExUnit.Case
  use PhoenixSwagger

  doctest PhoenixSwagger

  swagger_model :index do
    get "/api/v1/users"
    summary "Query for users"
    description "Query for users with paging and filtering"
    parameter :query, :'page[size]', :integer, "Number of elements per page", :required
    parameter :query, :'page[number]', :integer, "Number of the page"
    parameter :query, :'filter[sex]', :string, "Sex of the user"
    responses 200, "OK", ref: "#/definitions/Users"
  end

  test "produces expected swagger json" do
    assert swagger_index == %{
      "/api/v1/users" => %{
        "get" => %{
          "summary" => "Query for users",
          "description" => "Query for users with paging and filtering",
          "parameters" => [
            %{
              "description" => "Number of elements per page",
              "in" => "query",
              "name" => "page[size]",
              "required" => true,
              "type" => "integer"
            },
            %{
              "description" =>
              "Number of the page",
              "in" => "query",
              "name" => "page[number]",
              "required" => false,
              "type" => "integer"
            },
            %{
              "description" => "Sex of the user",
              "in" => "query",
              "name" => "filter[sex]",
              "required" => false,
              "type" => "string"
            }
          ],
          "responses" => %{
            "200" => %{
              "description" => "OK",
              "schema" =>  %{
                "$ref" => "#/definitions/Users"
              }
            }
          }
        }
      }
    }
  end
end
