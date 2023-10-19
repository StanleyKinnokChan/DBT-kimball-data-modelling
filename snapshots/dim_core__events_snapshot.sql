{% snapshot DIM_CORE__EVENTS_SNAPSHOT %}

{{ config(
	target_schema='core',
	unique_key='event_id',
    strategy='timestamp',
	updated_at='created_at',
	) 
}}


with CTE as (
	SELECT DISTINCT 
		event_id,
		event,
        sport,
		created_at
		FROM {{ ref('STG_ORIGIN__OLYMPICS_DATA') }}
	)

select 
	*
from CTE

{% endsnapshot %}