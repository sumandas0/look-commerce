with products as (
    select * from {{ ref('stg_thelook__products') }}
),

distribution_centers as (
    select * from {{ ref('stg_thelook__distribution_centers') }}
),

item_performance as (
    select
        product_id,
        count(*) as lifetime_units_ordered,
        sum(non_cancelled_item_count) as lifetime_units_sold,
        sum(completed_item_count) as lifetime_units_completed,
        sum(returned_item_count) as lifetime_units_returned,
        sum(cancelled_item_count) as lifetime_units_cancelled,
        sum(gross_sales_amount) as lifetime_gross_sales_amount,
        sum(refund_amount) as lifetime_refund_amount,
        sum(net_sales_amount) as lifetime_net_sales_amount,
        sum(gross_margin_amount) as lifetime_gross_margin_amount,
        min(ordered_at) as first_ordered_at,
        max(ordered_at) as most_recent_ordered_at
    from {{ ref('fct_order_items') }}
    group by product_id
)

select
    products.product_id,
    products.sku,
    products.product_name,
    products.brand,
    products.category,
    products.department,
    products.distribution_center_id,
    distribution_centers.distribution_center_name,
    products.unit_cost,
    products.retail_price,
    products.retail_price - products.unit_cost as standard_unit_margin_amount,
    safe_divide(products.retail_price - products.unit_cost, products.retail_price) as standard_margin_rate,
    coalesce(item_performance.lifetime_units_ordered, 0) as lifetime_units_ordered,
    coalesce(item_performance.lifetime_units_sold, 0) as lifetime_units_sold,
    coalesce(item_performance.lifetime_units_completed, 0) as lifetime_units_completed,
    coalesce(item_performance.lifetime_units_returned, 0) as lifetime_units_returned,
    coalesce(item_performance.lifetime_units_cancelled, 0) as lifetime_units_cancelled,
    coalesce(item_performance.lifetime_gross_sales_amount, 0) as lifetime_gross_sales_amount,
    coalesce(item_performance.lifetime_refund_amount, 0) as lifetime_refund_amount,
    coalesce(item_performance.lifetime_net_sales_amount, 0) as lifetime_net_sales_amount,
    coalesce(item_performance.lifetime_gross_margin_amount, 0) as lifetime_gross_margin_amount,
    safe_divide(item_performance.lifetime_units_returned, item_performance.lifetime_units_sold) as lifetime_item_return_rate,
    item_performance.first_ordered_at,
    item_performance.most_recent_ordered_at
from products
left join distribution_centers using (distribution_center_id)
left join item_performance using (product_id)

