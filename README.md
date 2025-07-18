# About
This project aims at demostrating how to perform Kimball data modelling in DBT. In this example, the data were normalized into 4 dimension tables and 1 fact table from a One Big Table (OBT) in Snowflake. The principle would be the same if the data source is in normalized form which requires the denormalization processs (e.g. from 3NF to star schema) in any OLAP datawarehouse.

![My Remote Image](https://i.imgur.com/p8e3Uj9.png)

**Features:**
- The raw data here minmic the a data stream being loaded into a selected datawarehouse (Snowflake in this example) after Extract and Load process, which grows over time. The dbt model enables us to perform the entire data modelling process, which can be also orchestrated by the tool like Airflow or Perfect. 
- When new data were added the source, the staging model will only loaded the new rows, greatly reducing the processing time.
- The new row will be added if the details of the old dimension members were modified or new dimension members were added.
- The model will be constructed only if the test has been successfully passed.
- Downstream model management and documentation can be extended and integrated with CI/CD process


**Noted that:**
- THe project is just for demostrating the process of modelling the data. However, in real life the modelling method depends on the real needs. For example, this olympic data contains the historical event, which may not requires a SCD type II capture.
 
<br/><br/>
# Content
- [Introduction]( )
- [Step 0. Project setup]( )
- [Step 1. Source & Staging Model]( )
- [Step 2. Dimention Tables]( )
- [Step 3. Fact Table]( )
- [Step 4. Primary key & foreign key with testing]( )
- [Step 5. Running the model]( )
- [Step 6. Exposure & Documentation]( )
<br/><br/>
# Introduction

## Why using DBT?
- **Modularity**: Bulk code breaking down into smaller & reusable pieces
- **Documentation**: Webpage documentation was generated by command `dbt docs generate` and `dbt docs serve`
- **Testing and Validation**: Here is done by Audit-helper package to ensure both original SQL and refactored SQL queries the exactly same result set
- **Dependency Management**: The reference of source is located at source folder. It would be the only things needed to be modified if the source schema is changed. All models were referenced with Jinja. 
- **Version Control**: Using GIT

## What is Kimball data modeling and its benefit?
Kimball data modeling, developed by data warehousing expert Ralph Kimball, is a methodology for designing data warehouse systems. It focuses on creating a flexible, user-friendly, and scalable data infrastructure to support business intelligence and analytics. Kimball's approach emphasizes simplicity and accessibility, making it easier for non-technical users to extract insights from data.

Key principles of Kimball data modeling include using a dimensional modeling technique, which involves creating star or snowflake schemas. These schemas organize data into fact tables (containing quantitative data) and dimension tables (containing descriptive attributes). This structure simplifies querying and reporting, as well as ensures data consistency and accuracy.

Additionally, Kimball promotes an iterative and collaborative development process, involving business stakeholders and IT teams to ensure alignment with business goals and evolving requirements. The methodology also encourages the use of ETL (Extract, Transform, Load) processes to transform and integrate data from various sources into the data warehouse.

## Environment Details
The project was developed using **DBT-core version** 1.6.3 within an **Anaconda** virtual environment 2023.07. It connects to the Snowflake datawarehouse with PyPI package **dbt-snowflake**. See https://docs.getdbt.com/docs/core/connect-data-platform/snowflake-setup

## Data source
The origin data sourced from originally sourced from [Kaggle](https://www.kaggle.com/datasets/bhanupratapbiswas/olympic-data?select=dataset_olympics.csv). The project idea was inspired by [Will Sutton](https://github.com/wjsutton/SQL_olympics/tree/main).

<br/><br/>
# Step 0. Project setup

#### Set up dbt
First, installing dbt-snowflake using `python -m pip install dbt-snowflake` and config the profiles.yml in %userprofile%/.dbt.  The example can be seen in [here](https://docs.getdbt.com/docs/core/connect-data-platform/snowflake-setup)

#### Create snowflake DB and schema for this project

Next, create warehouse, database and schema decidated to this project in Snowflake.
```sh
create warehouse demo_dbt WAREHOUSE_SIZE = Xsmall AUTO_SUSPEND = 60;
CREATE DATABSE DEMO_DBT_KIMBALL_DATA_MODELLING;
CREATE SCHEMA ORIGIN;
USE WAREHOUSE DEMO_DBT;
USE DEMO_DBT_KIMBALL_DATA_MODELLING.ORIGIN;
```

#### Set up the DBT project
The DBT project was initiated using `dbt innit`. Then csv file **OLYMPICS_DATA.csv** was put into the **seed** folder. These csv file was materialized in Snowflake table using `dbt seed` command. 

#### Import related packages
Two packages were used in this project. After putting the package name and version in the **packages.yml**, use `dbt deps` to import the packages.
```
packages:
  - package: Snowflake-Labs/dbt_constraints
    version: 0.6.2
  - package: dbt-labs/dbt_utils
    version: 1.1.1
```
Then install the package using `dbt deps`

#### Load the seed csv
Load the seed csv by the command `dbt seed`


<br/><br/>
# Step 1. Source & Staging Model
In this step the data were loaded from the source (the csv data that was uploaded in the previous step). In the model, we would use `{{ source(source_name, table_name) }}` jinja function to reference the source. To the set up the connection to the source, a sources.yml **sources.yml**  was created within **/model/staging** folder. 

Example of *sources.yml*:

![My Remote Image](https://i.imgur.com/wWRruak.png)


In the same folder, **stg_origin__OLYMPICS_DATA.sql** was also created. 
The data types were not optimized or set properly, such as extremely lengthy characters or number as characters. As a result, the columns were all casted into the optimized varchar length and correct type. 

There are no key for us to perform the dimension modelling. Therefore, `dbt_utils.generate_surrogate_key` function was utilized to create a unqiue surrogate key from the columns related to the same dimension with MD5 hashing function. 

The model was  set to be incremental; a new table will be materialized by running the first time. For the subsequent runs, only the new rows will be inserted into the existing table and processed if any downstreaming model references to this staging model. This can greatly improve the runtime when the source data was updated. 

Example of *stg_origin__OLYMPICS_DATA*:

![My Remote Image](https://i.imgur.com/8jlK1a0.png)
<br/><br/>
# Step 2. Dimention Tables
Four main aspects can be identified in the large table, they are: **athletes**, **teams**, **games** and **events**. There will be one dimention table for each aspect. The models will be saved in **/models/core** folder.

In the following model for athletes, the newly created surrogate key, as well as the corresponding info of the athletes in the staging model were selected. With the `distinct` keyword, the rows with the same key were elimliated. 

The dimension table SCD type II (new rows will be added to the dimension table if the item were modified or new item were added in the staging model), To achieve this, the materialization method was specified as **snapshot**. 

Example of *stg_origin__OLYMPICS_DATA*:

![My Remote Image](https://i.imgur.com/qZJe7gk.png)

The process repeated until all four dimension models were created
<br/><br/>
# Step 3. Fact Table
In the fact tables, it contains the most fundamental aspect, the result of the olympics (aka medal). Considering all keys were created in the staging model, and the dimensional columns were captured in the dimension table, the fact table can be created simply by selecting the ID of original sources, IDs of the dimension table and the measure medals. 

Example of *fct_core__results.sql*:

![My Remote Image](https://i.imgur.com/FKLew0Z.png)
<br/><br/>
# Step 4. Primary key & foreign key with testing
DBT eliminates the need of DDL and DML for creating our models. However, the primary key and foreign key were not automatically created when the tables were materialized in the datawarehouse. **dbt_constraints** allows us to perform primary key (unique and not null) and foreign key (referential integrity) testing. The correspondent key will be added to the datawarehouse if test were passed. 

For dimension model (primary key):

![My Remote Image](https://i.imgur.com/XbAIcDS.png)

For Fact model (Foreign key):

![My Remote Image](https://i.imgur.com/fSaGeNO.png)

Validated the model with the `dbt test`:

![My Remote Image](https://i.imgur.com/E269EUp.png)

For the data warehouse not supported by the dbt_constraints, we can make use of a combination of singular test, macro and post-hook function, in which you check the existence of key in the information with the table name. If the count(*)=0 then add the key. Here is an example I wrote: 

![My Remote Image](https://i.imgur.com/0Fosa8N.png)

# Step 5. Running the model
First the source model and fact table were built by `dbt run --full-refresh`.

Afterward, the fact table and the dimension tables can be incremental loaded by `dbt snapshot`.

<br/><br/>
# Step 6. Exposure & Documentation
For project management and documentation purpose, an exposure was added for recording the details of the downstream model consumer. It will also be shown in the DAG/ lineage graph. 

![My Remote Image](https://i.imgur.com/SaTS2QO.png)

Webpage documentation was generated by the command `dbt docs generate` and `dbt docs serve`

The DAG/ lineage graph created inside the documentation:

![My Remote Image](https://i.imgur.com/YQDxyiO.png)


You can also connect the datawarehouse to dBeaver to see the Entity Relationship (ER) Diagram:

![My Remote Image](https://i.imgur.com/jMzF0t4.png)

