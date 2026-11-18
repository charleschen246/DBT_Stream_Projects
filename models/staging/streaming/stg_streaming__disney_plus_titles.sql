with

source as (

    select * from {{ source('streaming', 'disney_plus_titles') }}

),

renamed as (

    select
        -- keys
        {{ dbt_utils.generate_surrogate_key(["'disney_plus'", 'show_id']) }} as title_key,
        'disney_plus' as platform_id,
        {{ clean_text('show_id') }} as show_id,

        -- attributes
        replace(lower({{ clean_text('type') }}), ' ', '_') as content_type,
        {{ clean_text('title') }} as title,
        {{ clean_text('director') }} as directors,
        {{ clean_text(adapter.quote('cast')) }} as cast_members,
        {{ clean_text('country') }} as countries,
        {{ clean_text('listed_in') }} as genres,
        upper({{ clean_text('rating') }}) as rating,
        {{ clean_text('duration') }} as duration,
        {{ clean_text('description') }} as description,

        -- dates
        cast(release_year as {{ dbt.type_int() }}) as release_year,
        {{ parse_text_date('date_added') }} as date_added

    from source

    where show_id is not null

)

select * from renamed
