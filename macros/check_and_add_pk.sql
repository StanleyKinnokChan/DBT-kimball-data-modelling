{% macro check_and_add_pk(table='DIM_CORE__ATHLETES_SNAPSHOT', prikey='athlete_id') %}


{% set pk_query %}
  SELECT count(*) FROM DEMO_DBT_KIMBALL_DATA_MODELLING.information_schema.table_constraints
  where table_name='{{ this.name }}' and CONSTRAINT_TYPE = 'PRIMARY KEY';
{% endset %}
{% set results = run_query(pk_query) %}

{% if execute %}
  {% set query_result = results.columns[0].values()[0] %}
{% else %}
  {% set query_result = [] %}
{% endif %}

{% set constraint_name = table ~ "_" ~ prikey ~ '_PK' %}

{% if query_result==0 %}
  {{log("Insert the following posthook:", info=True)}}
  ALTER TABLE {{ this }} ADD CONSTRAINT {{constraint_name}} PRIMARY KEY ({{ prikey }})
{% else %}
  {{log("There was Primary key on " ~ table ~ ". Process will be continued", info=True)}}
{% endif %}



{% endmacro %}