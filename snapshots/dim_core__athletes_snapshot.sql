{% snapshot DIM_CORE__ATHLETES_SNAPSHOT %}

{{ config(
	target_schema='core',
	unique_key='athlete_id',
    strategy='timestamp',
	updated_at='created_at',
	) 
}}

with CTE as (
	SELECT distinct
		athlete_id,
		name,
		sex, 
		height, 
		weight,
		created_at
	FROM {{ ref('STG_ORIGIN__OLYMPICS_DATA') }}
	)

SELECT
	*
FROM CTE

{% endsnapshot %}