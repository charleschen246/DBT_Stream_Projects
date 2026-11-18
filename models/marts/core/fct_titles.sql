with

titles as (

    select * from {{ ref('int_titles__enriched') }}

),

platforms as (

    select * from {{ ref('dim_platforms') }}

),

ratings as (

    select * from {{ ref('dim_ratings') }}

),

dates as (

    select * from {{ ref('dim_dates') }}

),

genre_counts as (

    select title_key, count(*) as genre_count
    from {{ ref('bridge_title_genres') }}
    group by title_key

),

country_counts as (

    select title_key, count(*) as country_count
    from {{ ref('bridge_title_countries') }}
    group by title_key

),

final as (

    select
        titles.title_key,
        platforms.platform_id,
        coalesce(ratings.rating_id, 'UNKNOWN') as rating_id,
        dates.date_day as date_added,

        titles.show_id,
        titles.title,
        titles.content_type,
        titles.source_content_type,
        titles.directors,
        titles.cast_members,
        titles.description,
        titles.release_year,
        titles.release_decade,

        titles.duration_minutes,
        titles.season_count,
        coalesce(genre_counts.genre_count, 0) as genre_count,
        coalesce(country_counts.country_count, 0) as country_count,
        titles.years_from_release_to_platform,

        titles.is_movie,
        titles.had_misplaced_duration,
        titles.is_content_type_corrected

    from titles
    inner join platforms
        on titles.platform_id = platforms.platform_id
    left join ratings
        on titles.rating_id = ratings.rating_id
    left join dates
        on titles.date_added = dates.date_day
    left join genre_counts
        on titles.title_key = genre_counts.title_key
    left join country_counts
        on titles.title_key = country_counts.title_key

)

select * from final
