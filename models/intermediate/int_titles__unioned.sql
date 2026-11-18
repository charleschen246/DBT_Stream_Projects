{%- set platforms = ['amazon_prime', 'disney_plus', 'hulu', 'netflix'] -%}

{#- Explicit column list so the UNION never depends on column order. -#}
{%- set columns = [
    'title_key', 'platform_id', 'show_id', 'content_type', 'title', 'directors',
    'cast_members', 'countries', 'genres', 'rating', 'duration', 'description',
    'release_year', 'date_added'
] -%}

with

{% for platform in platforms %}
{{ platform }} as (

    select
        {{ columns | join(',\n        ') }}
    from {{ ref('stg_streaming__' ~ platform ~ '_titles') }}

),

{% endfor %}

unioned as (

    {% for platform in platforms -%}
    select * from {{ platform }}
    {% if not loop.last %}union all
    {% endif %}
    {%- endfor %}

)

select * from unioned
