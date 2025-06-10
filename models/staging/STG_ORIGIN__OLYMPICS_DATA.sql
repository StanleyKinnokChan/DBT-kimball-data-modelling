{{
    config(
        materialized='incremental'
    )
}}

with source_data as (

    select
        cast(ID AS INT) AS ID,
        cast(Name AS VARCHAR(150)) AS Name,
        cast(Sex AS VARCHAR(100)) AS Sex,
        cast(Age AS INT) AS Age,
        cast(Height AS INT) AS Height,
        cast(Weight AS INT) AS Weight,
        cast(Team AS VARCHAR(50)) AS Team,
        cast(NOC AS VARCHAR(50)) AS NOC,
        cast(Games AS VARCHAR(100)) AS Games,
        cast(Year AS INT) AS Year,
        cast(Season AS VARCHAR(6)) AS Season,
        cast(City AS VARCHAR(25)) AS City,
        cast(Sport AS VARCHAR(25)) AS Sport,
        cast(Event AS VARCHAR(100)) AS Event,
        cast(Medal AS VARCHAR(6)) AS Medal,
        cast(NOC_Region AS VARCHAR(50)) AS NOC_Region,
        cast(NOC_notes AS VARCHAR(30)) AS NOC_notes,
        CURRENT_TIMESTAMP(4) as created_at,
        {{ dbt_utils.generate_surrogate_key(['name', 'sex','height','weight']) }} as athlete_id,
        {{ dbt_utils.generate_surrogate_key(['year', 'games','season','city']) }} as games_id,
        {{ dbt_utils.generate_surrogate_key(['event', 'sport','city']) }} as event_id,
        {{ dbt_utils.generate_surrogate_key(['team', 'noc','noc_region','NOC_notes']) }} as team_id
    FROM {{ source('sourcename','OLYMPICS_DATA') }}

)

select *
from source_data

{% if is_incremental() %}

  where ID > (select max(ID) from {{ this }})

{% endif %}