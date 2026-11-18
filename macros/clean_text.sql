{#- Trims whitespace and turns empty strings into NULL so "missing" means one thing. -#}
{% macro clean_text(column) -%}
    nullif(trim({{ column }}), '')
{%- endmacro %}
