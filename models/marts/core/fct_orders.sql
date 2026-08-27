{{ config(
    partition_by={"field": "ordered_date", "data_type": "date"},
    cluster_by=["order_status", "acquisition_channel", "customer_country"]
) }}

with orders as (
    select * from {{ ref('stg_thelook__orders') }}
),

customers as (
    select * from {{ ref('stg_thelook__users') }}
),

item_rollup as (
    select
        order_id,
        count(*) as order_item_count,
        sum(non_cancelled_item_count) as non_cancelled_item_count,
        sum(cancelled_item_count) as cancelled_item_count,
        sum(returned_item_count) as returned_item_count,
        sum(completed_item_count) as completed_item_count,
        sum(gross_sales_amount) as gross_sales_amount,
        sum(refund_amount) as refund_amount,
        sum(net_sales_amount) as net_sales_amount,
        sum(recognized_revenue_amount) as recognized_revenue_amount,
        sum(booked_cogs_amount) as booked_cogs_amount,
        sum(gross_margin_amount) as gross_margin_amount,
        sum(discount_amount) as discount_amount
    from {{ ref('fct_order_items') }}
    group by order_id
),

enriched as (
    select
        orders.order_id,
        orders.customer_id,
        orders.order_status,
        orders.customer_gender,
        customers.acquisition_channel,
        customers.country as customer_country,
        customers.state as customer_state,
        orders.ordered_at,
        date(orders.ordered_at) as ordered_date,
        orders.shipped_at,
        orders.delivered_at,
        orders.returned_at,
        coalesce(item_rollup.order_item_count, 0) as order_item_count,
        coalesce(item_rollup.non_cancelled_item_count, 0) as non_cancelled_item_count,
        coalesce(item_rollup.cancelled_item_count, 0) as cancelled_item_count,
        coalesce(item_rollup.returned_item_count, 0) as returned_item_count,
        coalesce(item_rollup.completed_item_count, 0) as completed_item_count,
        coalesce(item_rollup.gross_sales_amount, 0) as gross_sales_amount,
        coalesce(item_rollup.refund_amount, 0) as refund_amount,
        coalesce(item_rollup.net_sales_amount, 0) as net_sales_amount,
        coalesce(item_rollup.recognized_revenue_amount, 0) as recognized_revenue_amount,
        coalesce(item_rollup.booked_cogs_amount, 0) as booked_cogs_amount,
        coalesce(item_rollup.gross_margin_amount, 0) as gross_margin_amount,
        coalesce(item_rollup.discount_amount, 0) as discount_amount,
        case when orders.order_status != 'cancelled' then 1 else 0 end as is_valid_order,
        case when orders.order_status = 'cancelled' then 1 else 0 end as is_cancelled_order,
        case when orders.order_status = 'returned' then 1 else 0 end as is_returned_order,
        case when orders.order_status = 'complete' then 1 else 0 end as is_completed_order,
        case when orders.shipped_at is not null then 1 else 0 end as is_shipped_order,
        case
            when orders.shipped_at is not null
                and timestamp_diff(orders.shipped_at, orders.ordered_at, hour) <= 48 then 1
            else 0
        end as shipped_within_48h,
        case
            when orders.delivered_at is not null
                and timestamp_diff(orders.delivered_at, orders.ordered_at, hour) <= 120 then 1
            else 0
        end as delivered_within_5d,
        timestamp_diff(orders.shipped_at, orders.ordered_at, hour) as fulfillment_hours,
        timestamp_diff(orders.delivered_at, orders.ordered_at, hour) as delivery_hours,
        row_number() over (
            partition by orders.customer_id
            order by orders.ordered_at, orders.order_id
        ) as customer_order_number
    from orders
    left join item_rollup using (order_id)
    left join customers using (customer_id)
)

select
    *,
    case when customer_order_number = 1 then 1 else 0 end as is_first_order,
    case when customer_order_number > 1 then 1 else 0 end as is_repeat_order
from enriched

