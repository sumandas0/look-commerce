with events as (
    select * from {{ ref('stg_thelook__events') }}
)

select
    session_id,
    array_agg(customer_id ignore nulls order by event_at, sequence_number limit 1)[safe_offset(0)] as customer_id,
    coalesce(
        cast(array_agg(customer_id ignore nulls order by event_at, sequence_number limit 1)[safe_offset(0)] as string),
        concat('anonymous:', session_id)
    ) as visitor_key,
    min(event_at) as session_started_at,
    max(event_at) as session_ended_at,
    date(min(event_at)) as session_date,
    array_agg(traffic_source ignore nulls order by event_at, sequence_number limit 1)[safe_offset(0)] as traffic_source,
    array_agg(browser ignore nulls order by event_at, sequence_number limit 1)[safe_offset(0)] as browser,
    count(*) as event_count,
    countif(event_type = 'home') as home_event_count,
    countif(event_type = 'department') as department_event_count,
    countif(event_type = 'product') as product_view_count,
    countif(event_type = 'cart') as cart_event_count,
    countif(event_type = 'purchase') as purchase_event_count,
    countif(event_type = 'cancel') as cancel_event_count,
    case when countif(event_type = 'product') > 0 then 1 else 0 end as had_product_view,
    case when countif(event_type = 'cart') > 0 then 1 else 0 end as reached_cart,
    case when countif(event_type = 'purchase') > 0 then 1 else 0 end as converted,
    case when countif(event_type = 'cancel') > 0 then 1 else 0 end as had_cancellation,
    case
        when countif(event_type = 'cart') > 0 and countif(event_type = 'purchase') = 0 then 1
        else 0
    end as abandoned_cart,
    case
        when countif(event_type = 'purchase') > 0 then 'purchase'
        when countif(event_type = 'cart') > 0 then 'cart'
        when countif(event_type = 'product') > 0 then 'product_view'
        when countif(event_type = 'department') > 0 then 'department_view'
        else 'home'
    end as deepest_funnel_stage,
    timestamp_diff(max(event_at), min(event_at), second) / 60.0 as session_duration_minutes
from events
group by session_id
