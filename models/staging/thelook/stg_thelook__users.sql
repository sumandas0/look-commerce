select
    cast(id as int64) as customer_id,
    trim(first_name) as first_name,
    trim(last_name) as last_name,
    lower(trim(email)) as email,
    cast(age as int64) as age,
    lower(trim(gender)) as gender,
    trim(city) as city,
    trim(state) as state,
    trim(country) as country,
    cast(postal_code as string) as postal_code,
    lower(trim(traffic_source)) as acquisition_channel,
    cast(created_at as timestamp) as account_created_at,
    cast(latitude as float64) as latitude,
    cast(longitude as float64) as longitude
from {{ source('thelook', 'users') }}

