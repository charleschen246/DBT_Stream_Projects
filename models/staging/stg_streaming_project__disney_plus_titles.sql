{{ config(materialized='view') }}

with source as (

    select * from {{ source('streaming_project', 'disney_plus_titles') }}

),

renamed as (

    select
        show_id,
        type,
        title,
        director,
        cast,
        country,
        date_added,
        release_year,
        rating,
        duration,
        listed_in,
        description

    from source

)

select * from renamed