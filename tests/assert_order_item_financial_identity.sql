select *
from {{ ref('fct_order_items') }}
where
    net_sales_amount != gross_sales_amount - refund_amount
    or gross_margin_amount != net_sales_amount - booked_cogs_amount
    or refund_amount > gross_sales_amount
    or sale_price < 0

