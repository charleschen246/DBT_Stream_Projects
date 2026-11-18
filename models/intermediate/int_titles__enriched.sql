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

enriched as (

    select
        duration_parsed.title_key,
        duration_parsed.platform_id,
        duration_parsed.show_id,
        duration_parsed.content_type,
        duration_parsed.title,
        duration_parsed.directors,
        duration_parsed.cast_members,
        duration_parsed.countries,
        duration_parsed.genres,
        duration_parsed.description,

        -- rating
        duration_parsed.raw_rating,
        coalesce(rating_mappings.rating_id, 'UNKNOWN') as rating_id,

        -- duration
        duration_parsed.duration,
        case
            when duration_parsed.content_type = 'movie' and duration_parsed.duration_unit like 'min%'
                then duration_parsed.duration_value
        end as duration_minutes,
        case
            when duration_parsed.content_type = 'tv_show' and duration_parsed.duration_unit like 'season%'
                then duration_parsed.duration_value
        end as season_count,

        -- dates
        duration_parsed.release_year,
        duration_parsed.release_year - mod(duration_parsed.release_year, 10) as release_decade,
        duration_parsed.date_added,
        extract(year from duration_parsed.date_added) - duration_parsed.release_year
            as years_from_release_to_platform,

        -- flags
        duration_parsed.content_type = 'movie' as is_movie,
        duration_parsed.is_rating_misplaced as had_misplaced_duration

    from duration_parsed
    left join rating_mappings
        on duration_parsed.raw_rating = rating_mappings.raw_rating

)

select * from enriched
