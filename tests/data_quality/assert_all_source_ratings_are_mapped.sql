{{ config(severity='warn') }}

-- rating codes missing from seeds/rating_mappings.csv

select
    raw_rating,
    count(*) as title_count
from {{ ref('int_titles__enriched') }}
where raw_rating is not null
  and rating_id = 'UNKNOWN'
group by raw_rating
