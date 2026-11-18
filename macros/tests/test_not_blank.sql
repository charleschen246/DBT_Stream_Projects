{#
    Custom generic test: the column has no empty or whitespace-only strings.
    (not_null passes on '' and '   ', which are just as useless downstream.)
#}

{% test not_blank(model, column_name) %}

select {{ column_name }}
from {{ model }}
where {{ column_name }} is not null
  and trim(cast({{ column_name }} as {{ dbt.type_string() }})) = ''

{% endtest %}
