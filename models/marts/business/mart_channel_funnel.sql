select
    session_date,
    traffic_source,
    count(*) as session_count,
    count(distinct customer_id) as visitor_count,
    sum(had_product_view) as product_view_session_count,
    sum(reached_cart) as cart_session_count,
    sum(converted) as converting_session_count,
    sum(abandoned_cart) as abandoned_cart_session_count,
    sum(had_cancellation) as cancellation_session_count,
    sum(event_count) as event_count,
    safe_divide(sum(had_product_view), count(*)) as product_view_rate,
    safe_divide(sum(reached_cart), sum(had_product_view)) as product_to_cart_rate,
    safe_divide(sum(converted), sum(reached_cart)) as cart_to_purchase_rate,
    safe_divide(sum(converted), count(*)) as session_conversion_rate,
    safe_divide(sum(abandoned_cart), sum(reached_cart)) as cart_abandonment_rate
from {{ ref('fct_sessions') }}
group by session_date, traffic_source

