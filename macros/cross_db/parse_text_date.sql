{# 'September 25, 2021' -> date. Falls back to ISO, returns null if neither parses. #}

{% macro parse_text_date(column) -%}
    {{ return(adapter.dispatch('parse_text_date', 'streaming_analytics')(column)) }}
{%- endmacro %}

{% macro default__parse_text_date(column) -%}
    coalesce(
        safe.parse_date('%B %d, %Y', trim(cast({{ column }} as string))),
        safe.parse_date('%Y-%m-%d', trim(cast({{ column }} as string)))
    )
{%- endmacro %}

{% macro duckdb__parse_text_date(column) -%}
    cast(coalesce(
        try_strptime(trim(cast({{ column }} as varchar)), '%B %d, %Y'),
        try_strptime(trim(cast({{ column }} as varchar)), '%Y-%m-%d')
    ) as date)
{%- endmacro %}
