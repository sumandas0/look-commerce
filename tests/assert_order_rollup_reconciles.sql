with item_totals as (
    select
        order_id,
        count(*) as order_item_count,
        sum(net_sales_amount) as net_sales_amount,
        sum(refund_amount) as refund_amount,
        sum(gross_margin_amount) as gross_margin_amount
    from {{ ref('fct_order_items') }}
    group by order_id
)

select
    orders.order_id
from {{ ref('fct_orders') }} as orders
inner join item_totals using (order_id)
where
    orders.order_item_count != item_totals.order_item_count
    or orders.net_sales_amount != item_totals.net_sales_amount
    or orders.refund_amount != item_totals.refund_amount
    or orders.gross_margin_amount != item_totals.gross_margin_amount

