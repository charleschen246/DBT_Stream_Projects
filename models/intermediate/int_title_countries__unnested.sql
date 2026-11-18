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

-- trailing commas ('United States,') leave empty elements
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
