with customers as (
    select * from {{ ref('stg_thelook__users') }}
),

orders as (
    select * from {{ ref('fct_orders') }}
),

data_horizon as (
    select max(ordered_date) as as_of_date
    from orders
),

customer_orders as (
    select
        customer_id,
        min(ordered_at) as first_order_at,
        max(ordered_at) as most_recent_order_at,
        count(*) as lifetime_order_count,
        sum(is_valid_order) as lifetime_valid_order_count,
        sum(is_completed_order) as lifetime_completed_order_count,
        sum(is_cancelled_order) as lifetime_cancelled_order_count,
        sum(is_returned_order) as lifetime_returned_order_count,
        sum(non_cancelled_item_count) as lifetime_items_purchased,
        sum(returned_item_count) as lifetime_items_returned,
        sum(gross_sales_amount) as lifetime_gross_sales_amount,
        sum(refund_amount) as lifetime_refund_amount,
        sum(net_sales_amount) as lifetime_net_sales_amount,
        sum(gross_margin_amount) as lifetime_gross_margin_amount
    from orders
    group by customer_id
),

customer_base as (
    select
        customers.customer_id,
        customers.account_created_at,
        customers.age,
        customers.gender,
        customers.city,
        customers.state,
        customers.country,
        customers.postal_code,
        customers.acquisition_channel,
        case
            when customers.age < 25 then '18-24'
            when customers.age < 35 then '25-34'
            when customers.age < 45 then '35-44'
            when customers.age < 55 then '45-54'
            when customers.age < 65 then '55-64'
            else '65+'
        end as age_band,
        data_horizon.as_of_date,
        customer_orders.first_order_at,
        customer_orders.most_recent_order_at,
        coalesce(customer_orders.lifetime_order_count, 0) as lifetime_order_count,
        coalesce(customer_orders.lifetime_valid_order_count, 0) as lifetime_valid_order_count,
        coalesce(customer_orders.lifetime_completed_order_count, 0) as lifetime_completed_order_count,
        coalesce(customer_orders.lifetime_cancelled_order_count, 0) as lifetime_cancelled_order_count,
        coalesce(customer_orders.lifetime_returned_order_count, 0) as lifetime_returned_order_count,
        coalesce(customer_orders.lifetime_items_purchased, 0) as lifetime_items_purchased,
        coalesce(customer_orders.lifetime_items_returned, 0) as lifetime_items_returned,
        coalesce(customer_orders.lifetime_gross_sales_amount, 0) as lifetime_gross_sales_amount,
        coalesce(customer_orders.lifetime_refund_amount, 0) as lifetime_refund_amount,
        coalesce(customer_orders.lifetime_net_sales_amount, 0) as lifetime_net_sales_amount,
        coalesce(customer_orders.lifetime_gross_margin_amount, 0) as lifetime_gross_margin_amount,
        date_diff(data_horizon.as_of_date, date(customer_orders.most_recent_order_at), day) as days_since_last_order
    from customers
    cross join data_horizon
    left join customer_orders using (customer_id)
)

select
    *,
    1 as registered_customer_count,
    case when lifetime_valid_order_count > 0 then 1 else 0 end as purchasing_customer_count,
    case
        when lifetime_valid_order_count = 0 then 'prospect'
        when lifetime_valid_order_count >= 4 and lifetime_net_sales_amount >= 500 then 'champion'
        when lifetime_valid_order_count >= 3 then 'loyal'
        when lifetime_valid_order_count = 2 then 'repeat'
        else 'one_time'
    end as value_segment,
    case
        when lifetime_valid_order_count = 0 then 'never_purchased'
        when days_since_last_order <= 30 then 'active_30d'
        when days_since_last_order <= 90 then 'warm_31_90d'
        when days_since_last_order <= 180 then 'at_risk_91_180d'
        else 'lapsed_180d_plus'
    end as lifecycle_segment
from customer_base

