{% macro clean_text(column) -%}
    nullif(trim({{ column }}), '')
{%- endmacro %}
