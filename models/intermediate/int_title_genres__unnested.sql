-- One row per title per genre: 'Dramas, International Movies' becomes two rows.

with

titles as (

    select * from {{ ref('int_titles__enriched') }}

),

unnested as (

    select
        titles.title_key,
        titles.platform_id,
        titles.date_added,
        trim(genre) as genre_name
    from titles
    {{ unnest_delimited('titles.genres', 'genre') }}

),

-- A trailing comma in the source leaves an empty element, and a genre can be listed twice.
deduplicated as (

    select distinct
        title_key,
        platform_id,
        date_added,
        genre_name
    from unnested
    where genre_name != ''

)

select * from deduplicated
