defmodule PhoenixSwagger.Test.Schemas.Car do
  use PhoenixSwagger.SchemaDefinition

  swagger_schema do
    color :string, "Color", required: true, format: ".*"
    engine ref(:Engine), "The engine", required: true
    driver ref(:User), "The user driving the car"
    passengers array(:User), "Passengers in car"
    wheels array(:Wheel), "The wheels", required: true
    cargo array(:Luggage), "Luggage packed in the car"
  end
end
