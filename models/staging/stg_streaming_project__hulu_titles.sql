with 

source as (

    select * from {{ source('streaming_project', 'hulu_titles') }}

),

renamed as (

    select

    from source

)

select * from renamed
