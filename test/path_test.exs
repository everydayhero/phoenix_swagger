defmodule PhoenixSwagger.PathTest do
  use ExUnit.Case
  import PhoenixSwagger

  doctest PhoenixSwagger.Path

  swagger_path :index do
    get "/api/v1/users"
    summary "Query for users"
    description "Query for users with paging and filtering"
    produces "application/json"
    tag "Users"
    operation_id "list_users"
    paging
    parameter "filter[gender]", :query, :string, "Gender of the user", required: true, example: "Male"
    parameter "include", :query, :array, "Relationships to include", items: [type: :string, enum: [:organisation, :favourites, :purchases]], collectionFormat: :csv
    response 200, "OK", Schema.ref(:Users), example: %{id: 1, name: "Joe", email: "joe@gmail.com"}
    response 400, "Client Error"
  end

  swagger_path :create do
    post "/api/v1/{team}/users"
    summary "Create a new user"
    consumes "application/json"
    produces "application/json"
    tag "Users"
    parameter "user", :body, Schema.ref(:User), "user attributes"
    parameter "team", :path, :string, "Users team ID"
    response 200, "OK", Schema.ref(:User)
  end

   test "swagger_path_index produces expected swagger json" do
    assert swagger_path_index == %{
      "/api/v1/users" => %{
        "get" => %{
          "produces" => ["application/json"],
          "tags" => ["Users"],
          "operationId" => "list_users",
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
              "type" => "string",
              "x-example" => "Male"
            },
            %{
              "collectionFormat" => "csv",
              "description" => "Relationships to include",
              "in" => "query",
              "items" => %{
                "type" => "string",
                "enum" => ["organisation", "favourites", "purchases"]
              },
              "name" => "include",
              "required" => false,
              "type" => "array"
            }
          ],
          "responses" => %{
            "200" => %{
              "description" => "OK",
              "schema" =>  %{
                "$ref" => "#/definitions/Users"
              },
              "examples" => %{
                "application/json" => %{
                  "email" => "joe@gmail.com",
                  "id" => 1,
                  "name" => "Joe"
                }
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

  test "swagger_path_create produces expected swagger json" do
    assert swagger_path_create == %{
      "/api/v1/{team}/users" => %{
        "post" => %{
          "consumes" => ["application/json"],
          "description" => "",
          "operationId" => "PhoenixSwagger.PathTest.create",
          "parameters" => [
            %{
              "description" => "user attributes",
              "in" => "body",
              "name" => "user",
              "required" => false,
              "schema" => %{"$ref" => "#/definitions/User"},
            },
            %{
              "description" => "Users team ID",
              "in" => "path",
              "name" => "team",
              "required" => true,
              "type" => "string"
            }
          ],
          "produces" => ["application/json"],
          "responses" => %{
            "200" => %{
              "description" => "OK",
              "schema" => %{
                "$ref" => "#/definitions/User"
              }
            }
          },
          "summary" => "Create a new user",
          "tags" => ["Users"]
        }
      }
    }
  end
end
