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

## Using SpatiaLite with SQLite

### sqlite3 shell

The SpatiaLite library must be loaded via the `.load` command. For libspatialite installed via Homebrew on macOS, it would look something like this:

```sh
brew install spatialite-tools
```

```sh
sqlite3 app_dev.db
.load /opt/homebrew/lib/mod_spatialite.dylib
```

The command can be placed in `.sqliterc` to load it automatically.

### Ecto

The SpatiaLite extension must be loaded via Ecto's `load_extensions`. Using the previous example for Homebrew installation on macOS, the configuration would be:

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

Another example might be configuration for using runtime configuration to deploy to a Docker container.

```sh
RUN apt-get install libsqlite3-mod-spatialite
```

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
