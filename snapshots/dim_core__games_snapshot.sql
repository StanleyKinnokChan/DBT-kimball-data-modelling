{% snapshot DIM_CORE__GAMES_SNAPSHOT %}

{{ config(
	target_schema='core',
	unique_key='games_id',
    strategy='timestamp',
	updated_at='created_at',
	) 
}}


with CTE as (
	SELECT DISTINCT
		games_id,
		year, 
		games, 
		season, 
		city,
		created_at
	FROM {{ ref('stg_origin__OLYMPICS_DATA') }}
	)

select 
	*
FROM CTE

{% endsnapshot %}