with

platforms as (

    select * from {{ ref('platforms') }}

)

select
    platform_id,
    platform_name,
    parent_company
from platforms
