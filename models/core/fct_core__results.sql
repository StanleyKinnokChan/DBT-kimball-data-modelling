with CTE AS (

    select 
        ID,
        athlete_id,
        team_id,
        games_id,
        event_id,
        medal
    FROM {{ ref('STG_ORIGIN__OLYMPICS_DATA') }}
    )

select *
FROM CTE