with

title_countries as (

    select * from {{ ref('int_title_countries__unnested') }}

),

countries as (

    select * from {{ ref('dim_countries') }}

)

select
    title_countries.title_key,
    title_countries.platform_id,
    title_countries.date_added,
    countries.country_key,
    countries.country_name
from title_countries
inner join countries
    on title_countries.country_name = countries.country_name
