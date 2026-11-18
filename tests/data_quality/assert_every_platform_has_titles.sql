-- Every platform in the dimension must have titles in the fact table.
-- An empty platform usually means its source table failed to load.

select dim_platforms.platform_id
from {{ ref('dim_platforms') }} as dim_platforms
left join {{ ref('fct_titles') }} as fct_titles
    on dim_platforms.platform_id = fct_titles.platform_id
group by dim_platforms.platform_id
having count(fct_titles.title_key) = 0
