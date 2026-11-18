-- titles available on more than one platform

with

titles as (

    select
        lower(fct_titles.title) as normalized_title,
        fct_titles.content_type,
        fct_titles.release_year,
        dim_platforms.platform_name
    from {{ ref('fct_titles') }} as fct_titles
    inner join {{ ref('dim_platforms') }} as dim_platforms
        on fct_titles.platform_id = dim_platforms.platform_id

)

select
    normalized_title,
    content_type,
    release_year,
    count(distinct platform_name) as platform_count,
    {{ dbt.listagg('distinct platform_name', "', '") }} as platforms
from titles
group by normalized_title, content_type, release_year
having count(distinct platform_name) > 1
order by platform_count desc, normalized_title
