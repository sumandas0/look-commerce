{{ config(
    partition_by={"field": "ordered_date", "data_type": "date"},
    cluster_by=["order_item_status", "category", "customer_country"]
) }}

select * from {{ ref('int_order_items_enriched') }}

