with order_items as (
    select * from {{ ref('stg_thelook__order_items') }}
),

orders as (
    select * from {{ ref('stg_thelook__orders') }}
),

products as (
    select * from {{ ref('stg_thelook__products') }}
),

customers as (
    select * from {{ ref('stg_thelook__users') }}
),

distribution_centers as (
    select * from {{ ref('stg_thelook__distribution_centers') }}
)

select
    order_items.order_item_id,
    order_items.order_id,
    order_items.customer_id,
    order_items.product_id,
    order_items.inventory_item_id,
    products.sku,
    products.product_name,
    products.brand,
    products.category,
    products.department,
    products.distribution_center_id,
    distribution_centers.distribution_center_name,
    customers.country as customer_country,
    customers.state as customer_state,
    customers.acquisition_channel,
    order_items.order_item_status,
    orders.order_status,
    order_items.ordered_at,
    date(order_items.ordered_at) as ordered_date,
    order_items.shipped_at,
    order_items.delivered_at,
    order_items.returned_at,
    order_items.sale_price,
    products.retail_price,
    products.unit_cost,
    greatest(products.retail_price - order_items.sale_price, cast(0 as numeric)) as discount_amount,
    case when order_items.order_item_status != 'cancelled' then 1 else 0 end as non_cancelled_item_count,
    case when order_items.order_item_status = 'cancelled' then 1 else 0 end as cancelled_item_count,
    case when order_items.order_item_status = 'returned' then 1 else 0 end as returned_item_count,
    case when order_items.order_item_status = 'complete' then 1 else 0 end as completed_item_count,
    case
        when order_items.order_item_status != 'cancelled' then order_items.sale_price
        else cast(0 as numeric)
    end as gross_sales_amount,
    case
        when order_items.order_item_status = 'returned' then order_items.sale_price
        else cast(0 as numeric)
    end as refund_amount,
    case
        when order_items.order_item_status not in ('cancelled', 'returned') then order_items.sale_price
        else cast(0 as numeric)
    end as net_sales_amount,
    case
        when order_items.order_item_status = 'complete' then order_items.sale_price
        else cast(0 as numeric)
    end as recognized_revenue_amount,
    case
        when order_items.order_item_status != 'cancelled' then products.unit_cost
        else cast(0 as numeric)
    end as booked_cogs_amount,
    case
        when order_items.order_item_status not in ('cancelled', 'returned') then order_items.sale_price
        else cast(0 as numeric)
    end
    - case
        when order_items.order_item_status != 'cancelled' then products.unit_cost
        else cast(0 as numeric)
    end as gross_margin_amount,
    timestamp_diff(order_items.shipped_at, order_items.ordered_at, hour) as fulfillment_hours,
    timestamp_diff(order_items.delivered_at, order_items.ordered_at, hour) as delivery_hours,
    timestamp_diff(order_items.returned_at, order_items.delivered_at, hour) as return_lag_hours
from order_items
left join orders using (order_id)
left join products using (product_id)
left join customers on order_items.customer_id = customers.customer_id
left join distribution_centers using (distribution_center_id)
