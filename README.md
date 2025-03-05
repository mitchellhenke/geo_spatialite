# GeoSpatialite

Implements encoding and decoding [geo](https://github.com/felt/geo) geometries to [SpatiaLite format](https://www.gaia-gis.it/gaia-sins/BLOB-Geometry.html).

Geometries currently supported:

- Point
- LineString
- Polygon
- MultiPolygon

Geometries not yet supported:

- PointZ
- PointM
- PointZM
- LineStringZ
- LineStringZM
- PolygonZ
- MultiPointZ
- MultiLineString
- MultiLineStringZ
- MultiPoint
- MultiPolygonZ
- GeometryCollection

The TinyPoint encoding is also not yet supported.

## Installation

```elixir
def deps do
  [
    {:geo_spatialite, "~> 0.1.0"}
  ]
end
```

### Spatialite

#### macOS

```sh
brew install spatialite-tools
```

#### Debian

```sh
apt-get install libsqlite3-mod-spatialite
```

## Ecto

### Setup

Databases must initialize SpatiaLite via a migration and call extension-specific functions for managing columns and indexing.

```elixir
defmodule App.Repo.Migrations.InitializeSpatialite do
  use Ecto.Migration

  def change do
    execute(
      """
      SELECT InitSpatialMetaData();
      """
    )
  end
end

defmodule App.Repo.Migrations.CreateCats do
  use Ecto.Migration

  def change do
    create table(:cats) do
      add :name, :string
    end

    execute(
      """
      SELECT AddGeometryColumn('cats', 'geom_point', 4326, 'POINT');
      """,
      """
      SELECT DiscardGeometryColumn('cats', 'geom_point');
      ALTER TABLE cats DROP COLUMN geom_point;
      """
    )

    # Indexing (optional)
    execute(
      """
      SELECT CreateSpatialIndex('cats', 'geom_point');
      """,
      """
      SELECT DisableSpatialIndex('cats', 'geom_point');
      DROP INDEX idx_cats_geom_point;
      """
    )
  end
end
```

### Schema

```elixir
defmodule Cat do
  use Ecto.Schema

  schema "cats" do
    field :name, :string
    field :geom, GeoSpatialite.Geometry
  end
end
```


### Extension

The SpatiaLite extension must be loaded via the [load_extensions](https://hexdocs.pm/exqlite/Exqlite.Connection.html#connect/1) option. Assuming a Homebrew installation on macOS, the configuration would be something like:

```elixir
# config/dev.exs

config :app, App.Repo,
  database: Path.expand("../app_dev.db", Path.dirname(__ENV__.file)),
  pool_size: 5,
  stacktrace: true,
  load_extensions: [
    "/opt/homebrew/lib/mod_spatialite.dylib"
  ],
  show_sensitive_data_on_connection_error: true
```

Another example could be using runtime configuration to deploy to a Debian-based Docker container:

```elixir
# config/runtime.exs

  config :app, App.Repo,
    database: database_path,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "5"),
    custom_pragmas: [{"trusted_schema", true}],
    load_extensions: [
      "/usr/lib/x86_64-linux-gnu/mod_spatialite.so"
    ]
```
