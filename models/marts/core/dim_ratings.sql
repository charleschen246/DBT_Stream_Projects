with

rating_mappings as (

    select * from {{ ref('rating_mappings') }}

),

ratings as (

    select distinct
        rating_id,
        rating_system,
        audience_group,
        cast(audience_rank as {{ dbt.type_bigint() }}) as audience_rank
    from rating_mappings

),

-- so titles with a missing or unmapped rating still join
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
