with 

source as (

    select * from {{ source('streaming_project', 'src_netflix_titles') }}

),

renamed as (

    select

    from source

)

select * from renamed
