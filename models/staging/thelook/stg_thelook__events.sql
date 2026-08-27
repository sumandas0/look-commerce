select
    cast(id as int64) as event_id,
    cast(user_id as int64) as customer_id,
    cast(session_id as string) as session_id,
    cast(sequence_number as int64) as sequence_number,
    cast(created_at as timestamp) as event_at,
    lower(trim(event_type)) as event_type,
    lower(trim(browser)) as browser,
    lower(trim(traffic_source)) as traffic_source,
    trim(uri) as page_uri,
    trim(city) as city,
    trim(state) as state
from {{ source('thelook', 'events') }}

