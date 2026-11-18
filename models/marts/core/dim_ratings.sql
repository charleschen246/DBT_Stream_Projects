with

rating_mappings as (

    select * from {{ ref('rating_mappings') }}

),

-- The seed has one row per raw alias. Collapse it to one row per standardized rating.
ratings as (

    select distinct
        rating_id,
        rating_system,
        audience_group,
        cast(audience_rank as {{ dbt.type_bigint() }}) as audience_rank
    from rating_mappings

),

-- Fallback member so every fact row joins, even when the rating is missing or unmapped.
unknown_member as (

    select
        'UNKNOWN' as rating_id,
        'Unknown' as rating_system,
        'Unknown' as audience_group,
        cast(null as {{ dbt.type_bigint() }}) as audience_rank

)

select * from ratings
union all
select * from unknown_member
