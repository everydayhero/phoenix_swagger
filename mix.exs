defmodule PhoenixSwagger.Mixfile do
  use Mix.Project

  @version "0.1.4"

  def project do
    [app: :edh_phoenix_swagger,
     version: @version,
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     package: package,
     docs: [extras: ["README.md"], main: "readme",
              source_ref: "#{@version}",
              source_url: "https://github.com/everydayhero/phoenix_swagger"]]
  end

  def package do
    [name: :edh_phoenix_swagger,
     description: "Swagger DSL and Generator for Phoenix projects",
     files: ["lib", "mix.exs"],
     maintainers: ["Michael Buhot (m.buhot@gmail.com)", "Nick Chmielewski (nick.chmielewski@everydayhero.com)"],
     licenses: ["Mozilla Public License 2.0"],
     links: %{"Github" => "https://github.com/everydayhero/phoenix_swagger"}]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:credo, "~> 0.3", only: [:dev, :test]},
      {:ex_doc, ">= 0.13.0", only: :dev},
      {:inch_ex, only: :docs},
      {:poison, "~> 2.0"}
    ]
  end
end
