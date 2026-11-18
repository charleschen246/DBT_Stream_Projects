{#
    Custom generic test: an aggregate on this model must equal the same aggregate on another model.

    Used to prove nothing is dropped or duplicated as data moves stg -> int -> marts,
    e.g. "fct_titles has the same number of Netflix movies as stg_streaming__netflix_titles".

    Arguments:
        compare_model       the upstream model to reconcile against
        expression          aggregate on this model             (default: count(*))
        compare_expression  aggregate on compare_model          (default: same as expression)
        group_by            columns in this model to compare per group (optional)
        compare_group_by    matching columns in compare_model, if named differently (default: group_by)
        model_filter        WHERE clause for this model         (default: no filter)
        compare_filter      WHERE clause for compare_model      (default: no filter)
        tolerance           allowed absolute difference         (default: 0, exact match)

    Returns one row per group whose values differ, so a passing test returns zero rows.
#}

{% test metric_reconciles(
    model,
    compare_model,
    expression='count(*)',
    compare_expression=none,
    group_by=none,
    compare_group_by=none,
    model_filter='1 = 1',
    compare_filter='1 = 1',
    tolerance=0
) %}

{%- set compare_expression = compare_expression or expression -%}
{%- set group_by = group_by or [] -%}
{%- set compare_group_by = compare_group_by or group_by -%}
{%- if compare_group_by | length != group_by | length -%}
    {{ exceptions.raise_compiler_error("metric_reconciles: compare_group_by must have as many columns as group_by") }}
{%- endif -%}

with

model_agg as (

    select
        {%- for column in group_by %}
        coalesce(cast({{ column }} as {{ dbt.type_string() }}), '__null__') as {{ column }},
        {%- endfor %}
        {{ expression }} as model_value
    from {{ model }}
    where {{ model_filter }}
    {% if group_by %}group by {{ group_by | join(', ') }}{% endif %}

),

compare_agg as (

    select
        {%- for column in compare_group_by %}
        coalesce(cast({{ column }} as {{ dbt.type_string() }}), '__null__') as {{ group_by[loop.index0] }},
        {%- endfor %}
        {{ compare_expression }} as compare_value
    from {{ compare_model }}
    where {{ compare_filter }}
    {% if compare_group_by %}group by {{ compare_group_by | join(', ') }}{% endif %}

),

compared as (

    select
        {%- for column in group_by %}
        coalesce(model_agg.{{ column }}, compare_agg.{{ column }}) as {{ column }},
        {%- endfor %}
        model_agg.model_value,
        compare_agg.compare_value
    from model_agg
    {% if group_by -%}
    full outer join compare_agg
        on {% for column in group_by -%}
        model_agg.{{ column }} = compare_agg.{{ column }}
        {%- if not loop.last %} and {% endif %}
        {%- endfor %}
    {%- else -%}
    cross join compare_agg
    {%- endif %}

)

select *
from compared
where
    model_value is null
    or compare_value is null
    or abs(model_value - compare_value) > {{ tolerance }}

{% endtest %}
