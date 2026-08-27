select
    cast(id as int64) as distribution_center_id,
    trim(name) as distribution_center_name,
    cast(latitude as float64) as latitude,
    cast(longitude as float64) as longitude
from {{ source('thelook', 'distribution_centers') }}

