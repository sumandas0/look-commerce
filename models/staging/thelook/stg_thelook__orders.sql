select
    cast(order_id as int64) as order_id,
    cast(user_id as int64) as customer_id,
    lower(trim(status)) as order_status,
    lower(trim(gender)) as customer_gender,
    cast(created_at as timestamp) as ordered_at,
    cast(shipped_at as timestamp) as shipped_at,
    cast(delivered_at as timestamp) as delivered_at,
    cast(returned_at as timestamp) as returned_at,
    cast(num_of_item as int64) as order_item_quantity
from {{ source('thelook', 'orders') }}

