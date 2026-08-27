#!/usr/bin/env bash
set -euo pipefail

target_project="${1:-testing-cto-fivetranai}"
raw_dataset="${2:-raw_thelook_ecommerce}"
source_project="bigquery-public-data"
source_dataset="thelook_ecommerce"

if ! bq show --format=prettyjson "${target_project}:${raw_dataset}" >/dev/null 2>&1; then
    bq mk \
        --dataset \
        --location=US \
        --description="Snapshot of bigquery-public-data.thelook_ecommerce for dbt Data AI E2E testing" \
        "${target_project}:${raw_dataset}"
fi

tables=(
    distribution_centers
    events
    inventory_items
    order_items
    orders
    products
    users
)

for table_name in "${tables[@]}"; do
    target_table="${target_project}:${raw_dataset}.${table_name}"
    if bq show --format=prettyjson "${target_table}" >/dev/null 2>&1; then
        printf 'Already loaded: %s\n' "${target_table}"
    else
        bq cp \
            "${source_project}:${source_dataset}.${table_name}" \
            "${target_table}"
    fi
done

bq ls --project_id="${target_project}" "${raw_dataset}"

