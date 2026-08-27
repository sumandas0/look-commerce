select *
from {{ ref('mart_channel_funnel') }}
where
    session_conversion_rate not between 0 and 1
    or cart_abandonment_rate not between 0 and 1
    or cart_to_purchase_rate not between 0 and 1
    or product_view_rate not between 0 and 1
    or product_to_cart_rate not between 0 and 1

