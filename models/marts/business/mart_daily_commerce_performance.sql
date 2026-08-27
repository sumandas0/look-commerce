select
    ordered_date,
    count(*) as order_count,
    sum(is_valid_order) as valid_order_count,
    sum(is_cancelled_order) as cancelled_order_count,
    sum(is_returned_order) as returned_order_count,
    sum(is_completed_order) as completed_order_count,
    count(distinct if(is_valid_order = 1, customer_id, null)) as purchasing_customer_count,
    sum(case when is_first_order = 1 and is_valid_order = 1 then 1 else 0 end) as new_customer_order_count,
    sum(case when is_repeat_order = 1 and is_valid_order = 1 then 1 else 0 end) as repeat_customer_order_count,
    sum(order_item_count) as ordered_item_count,
    sum(non_cancelled_item_count) as sold_item_count,
    sum(returned_item_count) as returned_item_count,
    sum(gross_sales_amount) as gross_sales_amount,
    sum(refund_amount) as refund_amount,
    sum(net_sales_amount) as net_sales_amount,
    sum(recognized_revenue_amount) as recognized_revenue_amount,
    sum(booked_cogs_amount) as booked_cogs_amount,
    sum(gross_margin_amount) as gross_margin_amount,
    sum(discount_amount) as discount_amount,
    safe_divide(sum(net_sales_amount), sum(is_valid_order)) as average_order_value,
    safe_divide(sum(returned_item_count), sum(non_cancelled_item_count)) as item_return_rate,
    safe_divide(sum(is_cancelled_order), count(*)) as order_cancellation_rate,
    safe_divide(sum(shipped_within_48h), sum(is_shipped_order)) as fulfillment_sla_rate,
    avg(if(is_shipped_order = 1, fulfillment_hours, null)) as average_fulfillment_hours,
    avg(if(delivered_at is not null, delivery_hours, null)) as average_delivery_hours
from {{ ref('fct_orders') }}
group by ordered_date

