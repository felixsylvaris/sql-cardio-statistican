
--https://www.kaggle.com/datasets/akshatshaw7/cardiovascular-disease-dataset


-this is schema creation file
--drop old table
DROP TABLE IF EXISTS cardiovi;

--create new table
CREATE TABLE cardiovas (
    id SERIAL PRIMARY KEY,
    age INT,          -- typically in days, may want to convert to years
    gender INT,       -- 1: female, 2: male
    height INT,       -- cm
    weight INT,       -- kg
    ap_hi INT,        -- systolic
    ap_lo INT,        -- diastolic
    cholesterol INT,  -- 1: normal, 2: above normal, 3: high
    gluc INT,         -- 1: normal, 2: above normal, 3: high
    smoke BOOLEAN,
    alco BOOLEAN,
    active BOOLEAN,
    cardio BOOLEAN
);
--load some data. Use your actuall full path. 
COPY cardiovas(id, age, gender, height, weight, ap_hi, ap_lo, cholesterol, gluc, smoke, alco, active, cardio)
FROM '/full/path/to/health_data.csv'
DELIMITER ','
CSV HEADER;

--cheking records count
select count(*) from cardiovas;
--looking at out db
select * from cardiovas;

--checking for nulls
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

ALTER TABLE cardiovas
ALTER COLUMN age SET NOT NULL,
ALTER COLUMN gender SET NOT NULL,
ALTER COLUMN cardio SET NOT NULL;

ALTER TABLE cardiovas ADD COLUMN age_years NUMERIC(5,2);
UPDATE cardiovas
SET age_years = age / 365.0;

-- Add new column for BMI


--Some values are too suspicious 
DELETE FROM cardiovas
WHERE height < 120 OR height > 250
   OR weight < 40 OR weight > 150;

--we are flagging sus rows
ALTER TABLE cardiovas ADD COLUMN suspect BOOLEAN DEFAULT FALSE;
update cardiovas set suspect=false;
UPDATE cardiovas
SET suspect = TRUE
WHERE height NOT BETWEEN 100 AND 250
   OR weight NOT BETWEEN 40 AND 180
   OR age_years NOT BETWEEN 18 AND 125
   OR ap_hi NOT BETWEEN 60 AND 250  -- slightly relaxed
   OR ap_lo NOT BETWEEN 40 AND 150
   OR cholesterol NOT IN (0,1,2)
   OR gluc NOT IN (0,1,2);

select count(*) from cardiovas where suspect=TRUE;
--delete them
DELETE FROM cardiovas
WHERE suspect = TRUE;

select max(age_years), min(age_years) from cardiovas;

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
      AND bmi BETWEEN 10 AND 40
)
--SELECT COUNT(*) AS valid_bmi_count FROM bmi_table;
-- we can also check how many well behaved bmi we have
-- optionally, see the table
SELECT * FROM bmi_table ORDER BY bmi DESC;


