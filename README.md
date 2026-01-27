# Cardiovascular-Disease-Statistics-PostgreSQL

This project uses a cardiovascular disease dataset and demonstrates the use of statistical functions in PostgreSQL to explore risk factors and basic data analysis.

## Objectives
1. Identify factors that increase the probability of cardiovascular disease.
2. Showcase useful PostgreSQL functions for statistical analysis.

## Dataset
- Original dataset: [Kaggle – Cardiovascular Disease Dataset](https://www.kaggle.com/datasets/akshatshaw7/cardiovascular-disease-dataset)
- The repo includes a 1,000-row sample CSV for testing (`data/cardio_sample.csv`).  
- To use the full dataset, download the CSV from Kaggle and place it in `data/cardio.csv`.

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

-- Optional: add age in years
ALTER TABLE cardiovas ADD COLUMN age_years NUMERIC(5,2);
UPDATE cardiovas SET age_years = age / 365.0;
