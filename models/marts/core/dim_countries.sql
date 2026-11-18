with

title_countries as (

    select * from {{ ref('int_title_countries__unnested') }}

),

countries as (

    select distinct country_name
    from title_countries

)

select
    {{ dbt_utils.generate_surrogate_key(['country_name']) }} as country_key,
    country_name
from countries
