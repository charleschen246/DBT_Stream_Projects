{#
    Renders a lateral join that explodes a delimited string column into one row per element.
    Usage:
        select t.title_key, trim(genre) as genre_name
        from titles as t
        {{ unnest_delimited('t.genres', 'genre') }}
#}

{% macro unnest_delimited(column, alias, delimiter=',') -%}
    {{ return(adapter.dispatch('unnest_delimited', 'streaming_analytics')(column, alias, delimiter)) }}
{%- endmacro %}

{% macro default__unnest_delimited(column, alias, delimiter) -%}
    cross join unnest(split({{ column }}, '{{ delimiter }}')) as {{ alias }}
{%- endmacro %}

{% macro duckdb__unnest_delimited(column, alias, delimiter) -%}
    cross join unnest(string_split({{ column }}, '{{ delimiter }}')) as _unnested_{{ alias }}({{ alias }})
{%- endmacro %}
