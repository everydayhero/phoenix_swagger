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
      "required" => [],
      "properties" => %{
        "full_name" => %{
          "description" => "Full name",
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
      "required" => ["color", "driver"],
      "properties" => %{
        "color" => %{
          "description" => "Color",
          "type" => "string"
        },
        "driver" => %{
          "$ref" => "#/definitions/User"
        },
        "passenger" => %{
          "$ref" => "#/definitions/User"
        }
      }
    }
  end
end
