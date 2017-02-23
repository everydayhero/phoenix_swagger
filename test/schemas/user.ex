defmodule PhoenixSwagger.Test.Schemas.User do
  import PhoenixSwagger

  swagger_schema do
    full_name :string, "Full name"
    suffix :string, ~S'Name suffix</p>Example "Sr", "Jr"'
    address [:string, :null], "Street Address"
  end
end
