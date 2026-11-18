{{ config(severity='warn') }}

-- Warns when a platform publishes a rating code that isn't in the rating_mappings seed yet.
-- Those titles fall back to rating_id = 'UNKNOWN' until a row is added to the seed.

select
    raw_rating,
    count(*) as title_count
from {{ ref('int_titles__enriched') }}
where raw_rating is not null
  and rating_id = 'UNKNOWN'
group by raw_rating
