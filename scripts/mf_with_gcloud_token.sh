#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export DBT_TARGET=token
export DBT_BIGQUERY_TOKEN="$(gcloud auth print-access-token)"

cd "${project_root}"
exec uvx --from dbt-metricflow --with dbt-bigquery mf "$@"

