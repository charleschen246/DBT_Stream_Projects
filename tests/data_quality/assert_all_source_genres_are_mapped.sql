{{ config(severity='warn') }}

-- genre labels missing from seeds/genre_mappings.csv

select
    genre_name,
    count(*) as title_count
from {{ ref('int_title_genres__unnested') }}
where not is_genre_mapped
group by genre_name
