with

title_genres as (

    select * from {{ ref('int_title_genres__unnested') }}

),

genres as (

    select distinct genre_name
    from title_genres

)

select
    {{ dbt_utils.generate_surrogate_key(['genre_name']) }} as genre_key,
    genre_name
from genres
