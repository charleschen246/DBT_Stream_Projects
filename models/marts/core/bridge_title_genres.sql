-- Grain: one row per title per genre. Resolves the many-to-many between fct_titles and dim_genres.

with

title_genres as (

    select * from {{ ref('int_title_genres__unnested') }}

),

genres as (

    select * from {{ ref('dim_genres') }}

)

select
    title_genres.title_key,
    title_genres.platform_id,
    title_genres.date_added,
    genres.genre_key,
    genres.genre_name
from title_genres
inner join genres
    on title_genres.genre_name = genres.genre_name
