with

spine as (

    select * from {{ ref('metricflow_time_spine') }}

)

select
    date_day,
    extract(year from date_day) as calendar_year,
    extract(quarter from date_day) as calendar_quarter,
    extract(month from date_day) as calendar_month,
    extract(day from date_day) as day_of_month,
    cast({{ dbt.date_trunc('month', 'date_day') }} as date) as first_day_of_month,
    cast({{ dbt.date_trunc('year', 'date_day') }} as date) as first_day_of_year
from spine
