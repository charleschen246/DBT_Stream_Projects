-- per platform and content type: row count, distinct show_ids, sum of release_year and dated titles
-- must match between staging and fct_titles. uses source_content_type on the mart side because
-- int_titles__enriched corrects some content types.

{% set platforms = ['amazon_prime', 'disney_plus', 'hulu', 'netflix'] %}

with

staging as (

    {% for platform in platforms -%}
    select platform_id, content_type, show_id, release_year, date_added
    from {{ ref('stg_streaming__' ~ platform ~ '_titles') }}
    {% if not loop.last %}union all
    {% endif %}
    {%- endfor %}

),

staging_metrics as (

    select
        platform_id,
        content_type,
        count(*) as title_count,
        count(distinct show_id) as distinct_show_ids,
        coalesce(sum(release_year), 0) as release_year_checksum,
        count(date_added) as dated_titles
    from staging
    group by platform_id, content_type

),

mart_metrics as (

    select
        dim_platforms.platform_id,
        fct_titles.source_content_type as content_type,
        count(*) as title_count,
        count(distinct fct_titles.show_id) as distinct_show_ids,
        coalesce(sum(fct_titles.release_year), 0) as release_year_checksum,
        count(fct_titles.date_added) as dated_titles
    from {{ ref('fct_titles') }} as fct_titles
    inner join {{ ref('dim_platforms') }} as dim_platforms
        on fct_titles.platform_id = dim_platforms.platform_id
    group by dim_platforms.platform_id, fct_titles.source_content_type

),

compared as (

    select
        coalesce(staging_metrics.platform_id, mart_metrics.platform_id) as platform_id,
        coalesce(staging_metrics.content_type, mart_metrics.content_type) as content_type,
        staging_metrics.title_count as stg_title_count,
        mart_metrics.title_count as mart_title_count,
        staging_metrics.distinct_show_ids as stg_distinct_show_ids,
        mart_metrics.distinct_show_ids as mart_distinct_show_ids,
        staging_metrics.release_year_checksum as stg_release_year_checksum,
        mart_metrics.release_year_checksum as mart_release_year_checksum,
        staging_metrics.dated_titles as stg_dated_titles,
        mart_metrics.dated_titles as mart_dated_titles
    from staging_metrics
    full outer join mart_metrics
        on staging_metrics.platform_id = mart_metrics.platform_id
        and staging_metrics.content_type = mart_metrics.content_type

)

select *
from compared
where
    stg_title_count is null
    or mart_title_count is null
    or stg_title_count != mart_title_count
    or stg_distinct_show_ids != mart_distinct_show_ids
    or stg_release_year_checksum != mart_release_year_checksum
    or stg_dated_titles != mart_dated_titles
