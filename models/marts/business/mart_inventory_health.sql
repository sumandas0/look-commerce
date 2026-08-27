with inventory as (
    select * from {{ ref('stg_thelook__inventory_items') }}
),

products as (
    select * from {{ ref('stg_thelook__products') }}
),

distribution_centers as (
    select * from {{ ref('stg_thelook__distribution_centers') }}
),

data_horizon as (
    select date(max(greatest(inventory_created_at, coalesce(sold_at, inventory_created_at)))) as as_of_date
    from inventory
),

inventory_rollup as (
    select
        inventory.product_id,
        count(*) as inventory_units_received,
        countif(inventory.sold_at is not null) as inventory_units_sold,
        countif(inventory.sold_at is null) as inventory_units_on_hand,
        sum(if(inventory.sold_at is null, inventory.unit_cost, 0)) as inventory_on_hand_cost_amount,
        sum(if(inventory.sold_at is null, inventory.retail_price, 0)) as inventory_on_hand_retail_amount,
        avg(if(inventory.sold_at is not null, timestamp_diff(inventory.sold_at, inventory.inventory_created_at, day), null)) as average_days_to_sell,
        avg(if(inventory.sold_at is null, date_diff(data_horizon.as_of_date, date(inventory.inventory_created_at), day), null)) as average_on_hand_age_days,
        max(inventory.inventory_created_at) as most_recent_inventory_received_at
    from inventory
    cross join data_horizon
    group by inventory.product_id
),

sales_rollup as (
    select
        product_id,
        sum(non_cancelled_item_count) as ordered_units_sold,
        sum(returned_item_count) as ordered_units_returned,
        sum(net_sales_amount) as net_sales_amount,
        sum(gross_margin_amount) as gross_margin_amount
    from {{ ref('fct_order_items') }}
    group by product_id
)

select
    data_horizon.as_of_date,
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
    coalesce(inventory_rollup.inventory_units_received, 0) as inventory_units_received,
    coalesce(inventory_rollup.inventory_units_sold, 0) as inventory_units_sold,
    coalesce(inventory_rollup.inventory_units_on_hand, 0) as inventory_units_on_hand,
    coalesce(inventory_rollup.inventory_on_hand_cost_amount, 0) as inventory_on_hand_cost_amount,
    coalesce(inventory_rollup.inventory_on_hand_retail_amount, 0) as inventory_on_hand_retail_amount,
    inventory_rollup.average_days_to_sell,
    inventory_rollup.average_on_hand_age_days,
    inventory_rollup.most_recent_inventory_received_at,
    coalesce(sales_rollup.ordered_units_sold, 0) as ordered_units_sold,
    coalesce(sales_rollup.ordered_units_returned, 0) as ordered_units_returned,
    coalesce(sales_rollup.net_sales_amount, 0) as net_sales_amount,
    coalesce(sales_rollup.gross_margin_amount, 0) as gross_margin_amount,
    safe_divide(inventory_rollup.inventory_units_sold, inventory_rollup.inventory_units_received) as inventory_sell_through_rate,
    safe_divide(sales_rollup.ordered_units_returned, sales_rollup.ordered_units_sold) as ordered_item_return_rate
from products
cross join data_horizon
left join inventory_rollup using (product_id)
left join sales_rollup using (product_id)
left join distribution_centers using (distribution_center_id)

