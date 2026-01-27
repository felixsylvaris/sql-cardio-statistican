# Cardiovascular-Disease-Statistics-PostgreSQL

This project uses a cardiovascular disease dataset and demonstrates the use of statistical functions in PostgreSQL to explore risk factors and basic data analysis.

## Objectives
1. Identify factors that increase the probability of cardiovascular disease.
2. Showcase useful PostgreSQL functions for statistical analysis.

## Dataset
- Original dataset: [Kaggle – Cardiovascular Disease Dataset](https://www.kaggle.com/datasets/akshatshaw7/cardiovascular-disease-dataset)
- The repo includes a 1,000-row sample CSV for testing (`data/health_data_sample.csv`).  
- To use the full dataset, download the CSV from Kaggle and place it in `data/health_data.csv`.
*Version note:* We are using PostgreSQL (version 16 or higher) to ensure all statistical functions used in this project work correctly.


## Fields Description
| Field        | Description |
|--------------|------------|
| id           | Unique record identifier |
| age          | Age in days (can convert to years) |
| gender       | 1: female, 2: male |
| height       | Height in cm |
| weight       | Weight in kg |
| ap_hi        | Systolic blood pressure |
| ap_lo        | Diastolic blood pressure |
| cholesterol  | 1: normal, 2: above normal, 3: high |
| gluc         | Glucose level (1: normal, 2: above normal, 3: high) |
| smoke        | Smoker (TRUE/FALSE) |
| alco         | Alcohol consumption (TRUE/FALSE) |
| active       | Physical activity (TRUE/FALSE) |
| cardio       | Cardiovascular disease presence (TRUE/FALSE) |

## Creating Schema
Here is the PostgreSQL schema for the table:

    ```sql
    CREATE TABLE cardiovas(
        id SERIAL PRIMARY KEY,
        age INT,
        gender INT,
        height INT,
        weight INT,
        ap_hi INT,
        ap_lo INT,
        cholesterol INT,
        gluc INT,
        smoke BOOLEAN,
        alco BOOLEAN,
        active BOOLEAN,
        cardio BOOLEAN
    );
    ```
Loading data.

    ```sql
    --load some data. Use your actuall full path. 
    COPY cardiovas(id, age, gender, height, weight, ap_hi, ap_lo, cholesterol, gluc, smoke, alco, active, cardio)
    FROM '/data/health_data_sample.csv'
    DELIMITER ','
    CSV HEADER;

    --cheking records count
    select count(*) from cardiovas;
    ```
*Note:* This is pathway to this repo, you need to use local pahtway (full) and your file.
We check count records to be sure all loaded. 

### Data Cleaning
Cheking for NULLs.

    ```sql
    SELECT
        COUNT(*) FILTER (WHERE id IS NULL)       AS id_nulls,
        COUNT(*) FILTER (WHERE age IS NULL)      AS age_nulls,
        COUNT(*) FILTER (WHERE gender IS NULL)   AS gender_nulls,
        COUNT(*) FILTER (WHERE height IS NULL)   AS height_nulls,
        COUNT(*) FILTER (WHERE weight IS NULL)   AS weight_nulls,
        COUNT(*) FILTER (WHERE ap_hi IS NULL)    AS ap_hi_nulls,
        COUNT(*) FILTER (WHERE ap_lo IS NULL)    AS ap_lo_nulls,
        COUNT(*) FILTER (WHERE cholesterol IS NULL) AS cholesterol_nulls,
        COUNT(*) FILTER (WHERE gluc IS NULL)     AS gluc_nulls,
        COUNT(*) FILTER (WHERE smoke IS NULL)    AS smoke_nulls,
        COUNT(*) FILTER (WHERE alco IS NULL)     AS alco_nulls,
        COUNT(*) FILTER (WHERE active IS NULL)   AS active_nulls,
        COUNT(*) FILTER (WHERE cardio IS NULL)   AS cardio_nulls
    FROM cardiovas;
    ```
If all good, we could set some no nulls especially for key.

    ```sql
    ALTER TABLE cardiovas
    ALTER COLUMN age SET NOT NULL,
    ALTER COLUMN gender SET NOT NULL,
    ALTER COLUMN cardio SET NOT NULL;
    ```
Now we sellect rows where some values are outliners, possibly mistake in transcription or data collection or random swap of columns. 

    ```sql
    ALTER TABLE cardiovas ADD COLUMN suspect BOOLEAN DEFAULT FALSE;
    update cardiovas set suspect=false;
    UPDATE cardiovas
    SET suspect = TRUE
    WHERE height NOT BETWEEN 100 AND 250
       OR weight NOT BETWEEN 40 AND 180
       OR ap_hi NOT BETWEEN 60 AND 250  -- slightly relaxed
       OR ap_lo NOT BETWEEN 40 AND 150
       OR cholesterol NOT IN (0,1,2)
       OR gluc NOT IN (0,1,2);
    --we count how many rows are suspect
    select count(*) from cardiovas where suspect=TRUE;
    --delete them
    DELETE FROM cardiovas
    WHERE suspect = TRUE;
    --drop suspect
    ALTER TABLE cardiovas
    DROP COLUMN suspect;
    ```
1st spot suspicious rows. Count how many of them. Delete them if count is low. Drop suspect column, as it served its purpose.

### Creating new fields
**Add age in years.** We create new fields which will be useful for future analysis.
We create age but in years (not days).

    ```sql
    ALTER TABLE cardiovas ADD COLUMN age_years NUMERIC(5,2);
    UPDATE cardiovas
    SET age_years = age / 365.0;
    -- Check if new fields have normal range. 
    select max(age_years), min(age_years) from cardiovas;
    ```
*Note:* After creating new field we check if values are normal. Like 18-120 years.

**ADD BMI**  
We want to add Body Mass Index field, which is popular metric in health related studies.
We need to consider outlier data in db (dont count them).

    ```sql
    ALTER TABLE cardiovas ADD COLUMN bmi NUMERIC(5,2);
    --Remove old bmi
    UPDATE cardiovas
    SET bmi = NULL;
    -- Fill it with calculated BMI
    UPDATE cardiovas
    SET bmi = weight / POWER(height / 100.0, 2)
    WHERE height BETWEEN 120 and 250
      AND weight BETWEEN 40 AND 150;
    
    WITH bmi_table AS (
        SELECT height, weight, bmi
        FROM cardiovas
        WHERE bmi IS NOT NULL
          AND bmi BETWEEN 10 AND 50
    )
    --SELECT COUNT(*) AS valid_bmi_count FROM bmi_table;
    -- we can also check how many well behaved bmi we have
    -- optionally, see the table
    SELECT * FROM bmi_table ORDER BY bmi DESC;
    ```
We created field. Filled it with values. And cheked output. 
