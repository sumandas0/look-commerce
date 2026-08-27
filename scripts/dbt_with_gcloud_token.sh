#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dbt_command="${1:-build}"
if (( $# > 0 )); then
    shift
fi

export DBT_TARGET=token
export DBT_BIGQUERY_TOKEN="$(gcloud auth print-access-token)"

cd "${project_root}"
exec dbt "${dbt_command}" \
    --profiles-dir "${project_root}" \
    --target token \
    --no-version-check \
    "$@"

