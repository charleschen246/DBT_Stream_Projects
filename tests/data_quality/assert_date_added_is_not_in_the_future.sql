select
    title_key,
    platform_id,
    date_added
from {{ ref('fct_titles') }}
where date_added > current_date
