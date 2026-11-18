with

titles as (

    select * from {{ ref('int_titles__unioned') }}

),

rating_mappings as (

    select * from {{ ref('rating_mappings') }}

),

-- A few source rows have the duration typed into the rating column
-- (e.g. rating = '74 MIN', duration = NULL). Move those values back where they belong.
misplaced_values_fixed as (

    select
        *,
        coalesce(rating like '% MIN' or rating like '% SEASON%', false) as is_rating_misplaced
    from titles

),

realigned as (

    select
        title_key,
        platform_id,
        show_id,
        content_type,
        title,
        directors,
        cast_members,
        countries,
        genres,
        description,
        release_year,
        date_added,
        is_rating_misplaced,
        case when is_rating_misplaced then null else rating end as raw_rating,
        case
            when is_rating_misplaced and duration is null then lower(rating)
            else duration
        end as duration
    from misplaced_values_fixed

),

-- '90 min' -> 90 minutes; '3 Seasons' -> 3 seasons
duration_parsed as (

    select
        *,
        {{ dbt.safe_cast(dbt.split_part('duration', "' '", 1), dbt.type_bigint()) }} as duration_value,
        lower({{ dbt.split_part('duration', "' '", 2) }}) as duration_unit
    from realigned

),

-- Hulu labels some series as 'Movie' even though their duration is '2 Seasons'
-- (e.g. Blippi, Brassic). When the duration unit contradicts the type, trust the duration.
content_type_corrected as (

    select
        *,
        content_type as source_content_type,
        case
            when duration_unit like 'season%' then 'tv_show'
            when duration_unit like 'min%' then 'movie'
            else content_type
        end as corrected_content_type
    from duration_parsed

),

enriched as (

    select
        content_type_corrected.title_key,
        content_type_corrected.platform_id,
        content_type_corrected.show_id,
        content_type_corrected.corrected_content_type as content_type,
        content_type_corrected.source_content_type,
        content_type_corrected.title,
        content_type_corrected.directors,
        content_type_corrected.cast_members,
        content_type_corrected.countries,
        content_type_corrected.genres,
        content_type_corrected.description,

        -- rating
        content_type_corrected.raw_rating,
        coalesce(rating_mappings.rating_id, 'UNKNOWN') as rating_id,

        -- duration
        content_type_corrected.duration,
        case
            when content_type_corrected.duration_unit like 'min%'
                then content_type_corrected.duration_value
        end as duration_minutes,
        case
            when content_type_corrected.duration_unit like 'season%'
                then content_type_corrected.duration_value
        end as season_count,

        -- dates
        content_type_corrected.release_year,
        content_type_corrected.release_year - mod(content_type_corrected.release_year, 10) as release_decade,
        content_type_corrected.date_added,
        extract(year from content_type_corrected.date_added) - content_type_corrected.release_year
            as years_from_release_to_platform,

        -- flags
        content_type_corrected.corrected_content_type = 'movie' as is_movie,
        content_type_corrected.is_rating_misplaced as had_misplaced_duration,
        coalesce(
            content_type_corrected.corrected_content_type != content_type_corrected.source_content_type,
            false
        ) as is_content_type_corrected

    from content_type_corrected
    left join rating_mappings
        on content_type_corrected.raw_rating = rating_mappings.raw_rating

)

select * from enriched
