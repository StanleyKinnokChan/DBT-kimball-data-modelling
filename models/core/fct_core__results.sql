with CTE AS (

    select 
        ID,
        athlete_id,
        team_id,
        games_id,
        event_id,
        medal
    FROM {{ ref('stg_origin__OLYMPICS_DATA') }} s
    )

select *
FROM CTE