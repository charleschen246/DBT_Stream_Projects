with

titles as (

    select * from {{ ref('int_titles__enriched') }}

),

genre_mappings as (

    select * from {{ ref('genre_mappings') }}

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

-- trailing commas leave empty elements, and some titles list a genre twice
deduplicated as (

    select distinct
        title_key,
        platform_id,
        date_added,
        genre_name
    from unnested
    where genre_name != ''

),

mapped as (

    select
        deduplicated.title_key,
        deduplicated.platform_id,
        deduplicated.date_added,
        deduplicated.genre_name,
        coalesce(genre_mappings.genre_group, 'Other') as genre_group,
        genre_mappings.genre_group is not null as is_genre_mapped
    from deduplicated
    left join genre_mappings
        on lower(deduplicated.genre_name) = lower(genre_mappings.raw_genre)

)

select * from mapped
