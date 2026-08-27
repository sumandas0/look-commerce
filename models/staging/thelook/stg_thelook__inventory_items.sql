select
    cast(id as int64) as inventory_item_id,
    cast(product_id as int64) as product_id,
    cast(created_at as timestamp) as inventory_created_at,
    cast(sold_at as timestamp) as sold_at,
    cast(cost as numeric) as unit_cost,
    trim(product_category) as category,
    trim(product_name) as product_name,
    trim(product_brand) as brand,
    cast(product_retail_price as numeric) as retail_price,
    trim(product_department) as department,
    cast(product_sku as string) as sku,
    cast(product_distribution_center_id as int64) as distribution_center_id
from {{ source('thelook', 'inventory_items') }}

