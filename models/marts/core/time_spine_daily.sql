select date_day
from unnest(
    generate_date_array(date('2018-01-01'), date('2030-12-31'), interval 1 day)
) as date_day

