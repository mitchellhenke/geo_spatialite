defmodule GeoSpatialite.MixProject do
  use Mix.Project

  def project do
    [
      app: :geo_spatialite,
      version: "0.2.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Encoder and decoder for SpatiaLite geometries",
      package: package(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:geo, "~> 3.6 or ~> 4.0"},
      {:ecto, "~> 3.0", optional: true},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false}
    ]
  end

  defp package do
    # These are the default files included in the package
    [
      files: ["lib", "mix.exs", "README.md", "CHANGELOG.md"],
      maintainers: ["Mitchell Henke"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/mitchellhenke/geo_spatialite"}
    ]
  end

  defp docs do
    [
      extras: ["CHANGELOG.md", "README.md"],
      main: "readme",
      source_url: "https://github.com/mitchellhenke/geo_spatialite",
      source_ref: "main",
      formatters: ["html"]
    ]
  end
end
