
# PostgreSQL (postgres)

PostgreSQL is a powerful, open source object-relational database system with over 35 years of active development that has earned it a strong reputation for reliability, feature robustness, and performance.

## Example Usage

```json
"features": {
    "ghcr.io/ccavolt/devcontainer-features/postgres:0": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select the version of PostgreSQL to install. | string | latest |
| pguser | Name of postgres user. | string | postgres |
| pgpassword | Password for postgres account. | string | postgres |
| pgencoding | Postgres encoding (character set) | string | UTF8 |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/ccavolt/devcontainer-features/blob/main/src/postgres/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
