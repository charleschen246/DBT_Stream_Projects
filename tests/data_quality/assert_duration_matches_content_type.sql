select
    title_key,
    platform_id,
    content_type,
    duration_minutes,
    season_count
from {{ ref('fct_titles') }}
where
    (content_type = 'movie' and season_count is not null)
    or (content_type = 'tv_show' and duration_minutes is not null)
