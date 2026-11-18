{# not_null lets empty strings through #}

{% test not_blank(model, column_name) %}

select {{ column_name }}
from {{ model }}
where {{ column_name }} is not null
  and trim(cast({{ column_name }} as {{ dbt.type_string() }})) = ''

{% endtest %}
