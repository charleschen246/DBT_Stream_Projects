-- One row per title per production country: 'United States, India' becomes two rows.

with

titles as (

    select * from {{ ref('int_titles__enriched') }}

),

unnested as (

    select
        titles.title_key,
        titles.platform_id,
        titles.date_added,
        trim(country) as country_name
    from titles
    {{ unnest_delimited('titles.countries', 'country') }}

),

-- Netflix rows often end with a trailing comma ('United States,'), which leaves an empty element.
deduplicated as (

    select distinct
        title_key,
        platform_id,
        date_added,
        country_name
    from unnested
    where country_name != ''

)

select * from deduplicated
