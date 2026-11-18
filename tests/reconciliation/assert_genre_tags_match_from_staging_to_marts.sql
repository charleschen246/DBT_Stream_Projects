-- splits genres straight from staging (skipping the intermediate layer) and checks the
-- bridge table ends up with the same number of title/genre pairs per platform

{% set platforms = ['amazon_prime', 'disney_plus', 'hulu', 'netflix'] %}

with

staging as (

    {% for platform in platforms -%}
    select title_key, platform_id, genres
    from {{ ref('stg_streaming__' ~ platform ~ '_titles') }}
    {% if not loop.last %}union all
    {% endif %}
    {%- endfor %}

),

staging_tags as (

    select distinct
        staging.title_key,
        staging.platform_id,
        trim(genre) as genre_name
    from staging
    {{ unnest_delimited('staging.genres', 'genre') }}

),

staging_counts as (

    select platform_id, count(*) as genre_tags
    from staging_tags
    where genre_name != ''
    group by platform_id

),

mart_counts as (

    select platform_id, count(*) as genre_tags
    from {{ ref('bridge_title_genres') }}
    group by platform_id

)

select
    coalesce(staging_counts.platform_id, mart_counts.platform_id) as platform_id,
    staging_counts.genre_tags as stg_genre_tags,
    mart_counts.genre_tags as mart_genre_tags
from staging_counts
full outer join mart_counts
    on staging_counts.platform_id = mart_counts.platform_id
where
    staging_counts.genre_tags is null
    or mart_counts.genre_tags is null
    or staging_counts.genre_tags != mart_counts.genre_tags
