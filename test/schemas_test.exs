defmodule PhoenixSwagger.JsonSchemaTest do
  use ExUnit.Case
  alias PhoenixSwagger.Schema
  alias PhoenixSwagger.Test.Schemas.{Book,Car,User}
  import PhoenixSwagger

  swagger_definitions do
    [
      User: User.schema,
      Book: Book.schema,
      Car: Car.schema
    ]
  end

  test "produces a User definition" do
    user_schema = swagger_definitions["User"]

    assert user_schema == %{
      "type" => "object",
      "properties" => %{
        "full_name" => %{
          "description" => "Full name",
          "type" => "string"
        },
        "suffix" => %{
          "description" => ~S'Name suffix</p>Example "Sr", "Jr"',
          "type" => "string"
        }
      }
    }
  end

  test "produces a Book definition" do
    book_schema = swagger_definitions["Book"]

    assert book_schema == %{
      "type" => "object",
      "required" => ["title", "author"],
      "properties" => %{
        "title" => %{
          "description" => "Title",
          "type" => "string"
        },
        "author" => %{
          "description" => "Author",
          "type" => "string"
        }
      }
    }
  end

  test "produces a Car definition" do
    car_schema = swagger_definitions["Car"]

    assert car_schema == %{
      "type" => "object",
      "required" => ["color", "engine", "wheels"],
      "properties" => %{
        "color" => %{
          "description" => "Color",
          "type" => "string",
          "format" => ".*"
        },
        "driver" => %{
          "description" => "The user driving the car",
          "$ref" => "#/definitions/User"
        },
        "engine" => %{
          "description" => "The engine",
          "$ref" => "#/definitions/Engine"
        },
        "cargo" => %{
          "description" => "Luggage packed in the car",
          "items" => %{
            "$ref" => "#/definitions/Luggage"
          },
          "type" => "array"
        },
        "passengers" => %{
          "description" => "Passengers in car",
          "items" => %{
            "$ref" => "#/definitions/User"
          },
          "type" => "array"
        },
        "wheels" => %{
          "description" => "The wheels",
          "items" => %{
            "$ref" => "#/definitions/Wheel"
          },
          "type" => "array"
        }
      }
    }
  end
end
