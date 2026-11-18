-- One Big Table: the star schema flattened into one wide table for BI tools and ad-hoc analysis.
-- Grain: one row per title per platform (same as fct_titles).
-- Genres and countries are rolled up into comma-separated lists so the grain doesn't fan out.

with

titles as (

    select * from {{ ref('fct_titles') }}

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

title_genres as (

    select * from {{ ref('bridge_title_genres') }}

),

title_countries as (

    select * from {{ ref('bridge_title_countries') }}

),

genres_rolled_up as (

    select
        title_key,
        {{ dbt.listagg('genre_name', "', '", 'order by genre_name') }} as genres,
        {{ dbt.listagg('distinct genre_group', "', '", 'order by genre_group') }} as genre_groups
    from title_genres
    group by title_key

),

countries_rolled_up as (

    select
        title_key,
        {{ dbt.listagg('country_name', "', '", 'order by country_name') }} as countries
    from title_countries
    group by title_key

),

final as (

    select
        -- title
        titles.title_key,
        titles.show_id,
        titles.title,
        titles.content_type,
        titles.is_movie,
        titles.description,
        titles.directors,
        titles.cast_members,

        -- platform
        platforms.platform_id,
        platforms.platform_name,
        platforms.parent_company,

        -- rating
        ratings.rating_id,
        ratings.rating_system,
        ratings.audience_group,
        ratings.audience_rank,

        -- release
        titles.release_year,
        titles.release_decade,

        -- date added
        titles.date_added,
        dates.calendar_year as added_year,
        dates.calendar_quarter as added_quarter,
        dates.calendar_month as added_month,
        dates.first_day_of_month as added_month_start,
        titles.years_from_release_to_platform,

        -- duration
        titles.duration_minutes,
        titles.season_count,

        -- genres and countries
        titles.genre_count,
        genres_rolled_up.genres,
        genres_rolled_up.genre_groups,
        titles.country_count,
        countries_rolled_up.countries,

        -- data quality
        titles.had_misplaced_duration,
        titles.is_content_type_corrected

    from titles
    inner join platforms
        on titles.platform_id = platforms.platform_id
    inner join ratings
        on titles.rating_id = ratings.rating_id
    left join dates
        on titles.date_added = dates.date_day
    left join genres_rolled_up
        on titles.title_key = genres_rolled_up.title_key
    left join countries_rolled_up
        on titles.title_key = countries_rolled_up.title_key

)

select * from final
