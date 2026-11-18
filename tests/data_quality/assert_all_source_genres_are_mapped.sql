{{ config(severity='warn') }}

-- Warns when a platform publishes a genre label that isn't in the genre_mappings seed yet.
-- Those titles fall back to genre_group = 'Other' until a row is added to the seed.

select
    genre_name,
    count(*) as title_count
from {{ ref('int_title_genres__unnested') }}
where not is_genre_mapped
group by genre_name
