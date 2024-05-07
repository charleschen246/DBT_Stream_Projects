with 

source as (

    select * from {{ source('streaming_project', 'src_amazon_prime_titles') }}

),

renamed as (

    select

    from source

)

select * from renamed
