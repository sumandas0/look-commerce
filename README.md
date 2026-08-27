# Look Commerce: BigQuery + dbt + Semantic Layer E2E

This project is a working ecommerce analytics stack in the GCP project
`testing-cto-fivetranai`. It snapshots Google's synthetic TheLook source,
builds tested dimensional and decision-oriented marts, and exposes governed
metrics through dbt's Fusion-native Semantic Layer format.

## Warehouse layout

| Dataset | Purpose |
| --- | --- |
| `raw_thelook_ecommerce` | Project-local copies of all seven public source tables |
| `analytics_thelook_staging` | Seven typed, normalized, privacy-reduced staging views |
| `analytics_thelook_marts` | Facts, dimensions, business marts, and the MetricFlow time spine |
| `analytics_thelook` | Base dbt target dataset used for connection and catalog operations |

The dbt graph contains 18 models in total, including a daily time spine:

- Core facts: `fct_orders`, `fct_order_items`, `fct_sessions`
- Conformed dimensions: `dim_customers`, `dim_products`
- Business marts: `mart_daily_commerce_performance`, `mart_channel_funnel`,
  `mart_inventory_health`
- Semantic support: `time_spine_daily` from 2018-01-01 through 2030-12-31

Intermediate order-item and session models are ephemeral, so they add lineage
and reuse without creating unnecessary warehouse objects.

## Business use cases

| Audience | Decision supported | Main assets |
| --- | --- | --- |
| Executive / finance | Demand, net sales, recognized revenue, returns, COGS, and margin | `fct_orders`, `fct_order_items`, daily commerce mart |
| Growth | Product-view, cart, purchase, conversion, and abandonment by channel/browser | `fct_sessions`, channel funnel mart |
| Merchandising | Category, brand, and product sales, returns, and margin | `fct_order_items`, `dim_products` |
| Operations | 48-hour ship SLA and five-day delivery SLA | `fct_orders`, daily commerce mart |
| Supply chain | On-hand units/value, inventory age, days to sell, and sell-through | inventory health mart |
| CRM | Customer value and deterministic lifecycle segments | `dim_customers` |

### Commercial metric contract

- **Gross sales**: sale price for every non-cancelled item, including later returns.
- **Refunds**: sale price for items currently in returned status.
- **Net sales**: gross sales minus refunds; cancellations contribute zero.
- **Recognized revenue**: sale price only for items in complete status.
- **Booked COGS**: catalog unit cost for every non-cancelled item.
- **Gross margin**: net sales minus booked COGS, retaining the cost impact of returns.

These definitions are implemented once in `fct_order_items` and reused by
order rollups, marts, tests, and semantic metrics.

## Run from scratch

Prerequisites are an authenticated `gcloud`/`bq` CLI with BigQuery permissions,
dbt Fusion, and `uv` for local MetricFlow execution.

```bash
./scripts/load_thelook.sh
./scripts/dbt_with_gcloud_token.sh build --write-json --write-catalog
./scripts/mf_with_gcloud_token.sh validate-configs --skip-dw --show-all
```

The token wrappers mint a short-lived access token with
`gcloud auth print-access-token`; no credential or token is written into this
repository. If Application Default Credentials are current, normal OAuth also
works:

```bash
dbt build --profiles-dir .
```

## Query governed metrics

Category economics:

```bash
./scripts/mf_with_gcloud_token.sh query \
  --metrics net_sales,gross_margin,item_return_rate \
  --group-by order_item__category \
  --order=-net_sales \
  --limit 5
```

Acquisition funnel:

```bash
./scripts/mf_with_gcloud_token.sh query \
  --metrics sessions,session_conversion_rate,cart_abandonment_rate \
  --group-by session__traffic_source \
  --order=-sessions
```

The project currently exposes 47 governed metrics spanning commerce, customer,
web funnel, fulfillment, and inventory decisions. Run this to list them:

```bash
./scripts/dbt_with_gcloud_token.sh list --resource-type metric --output name
```

`dbt sl validate` and `dbt sl query` require a linked dbt Platform project in
`dbt_cloud.yml`. For this local project, the official MetricFlow CLI provides
the equivalent semantic validation and query execution.

## Data-quality and modeling notes

- The public source is synthetic and changes over time. The raw tables are
  copied into the target project so one E2E run is internally consistent.
- Anonymous web events have null `customer_id`. Sessions preserve them through
  a deterministic `visitor_key` while keeping the customer entity nullable.
- Web events contain no trustworthy order ID. The funnel mart deliberately does
  not claim channel-level revenue attribution.
- Customer segmentation is relative to the snapshot's maximum order date, not
  wall-clock `current_date`, so repeated builds of the same snapshot are stable.
- Synthetic customer PII exists only in staging. Names and email addresses are
  excluded from marts and Semantic Layer dimensions.
- Source events can extend a few days beyond the run date. The stable time spine
  and source-relative `as_of_date` keep those records queryable and deterministic.

## Validation coverage

The project includes primary-key, relationship, accepted-value, and not-null
tests plus business assertions that:

- item financial identities reconcile (`net = gross - refunds`,
  `margin = net - COGS`);
- order financials exactly reconcile to their order items;
- funnel rates stay between zero and one;
- daily and composite business grains remain unique.
