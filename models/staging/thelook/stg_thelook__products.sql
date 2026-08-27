select
    cast(id as int64) as product_id,
    cast(sku as string) as sku,
    trim(name) as product_name,
    trim(brand) as brand,
    trim(category) as category,
    trim(department) as department,
    cast(cost as numeric) as unit_cost,
    cast(retail_price as numeric) as retail_price,
    cast(distribution_center_id as int64) as distribution_center_id
from {{ source('thelook', 'products') }}

