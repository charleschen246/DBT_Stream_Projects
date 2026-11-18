{# lateral join that turns 'a, b, c' into one row per element #}

{% macro unnest_delimited(column, alias, delimiter=',') -%}
    {{ return(adapter.dispatch('unnest_delimited', 'streaming_analytics')(column, alias, delimiter)) }}
{%- endmacro %}

{% macro default__unnest_delimited(column, alias, delimiter) -%}
    cross join unnest(split({{ column }}, '{{ delimiter }}')) as {{ alias }}
{%- endmacro %}

{% macro duckdb__unnest_delimited(column, alias, delimiter) -%}
    cross join unnest(string_split({{ column }}, '{{ delimiter }}')) as _unnested_{{ alias }}({{ alias }})
{%- endmacro %}
