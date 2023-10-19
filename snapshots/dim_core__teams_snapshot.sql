{% snapshot DIM_CORE__TEAMS_SNAPSHOT %}

{{ config(
	target_schema='core',
	unique_key='team_id',
    strategy='timestamp',
	updated_at='created_at',
	) 
}}


with CTE as (
	SELECT DISTINCT 
		team_id,
		team,
		noc,
		noc_region,
		NOC_notes,
		created_at
	FROM {{ ref('STG_ORIGIN__OLYMPICS_DATA') }}
	)
	
select 
	*
FROM CTE

{% endsnapshot %}