
# pgAdmin4 (pgadmin4)

pgAdmin is the most popular and feature rich Open Source administration and development platform for PostgreSQL, the most advanced Open Source database in the world. Doesn't work on arm64 (Apple Silicon).

## Example Usage

```json
"features": {
    "ghcr.io/ccavolt/devcontainer-features/pgadmin4:0": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| email | Email/username for pgAdmin web interface. | string | john@smith.dev |
| password | Password for pgAdmin web interface. Must be at least 6 characters. | string | asdfasdf |
| version | Select the version of pgAdmin4 to install. | string | latest |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/ccavolt/devcontainer-features/blob/main/src/pgadmin4/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
