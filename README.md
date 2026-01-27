# Cardiovascular-Disease-Statistics-PostgreSQL

This project uses a cardiovascular disease dataset and demonstrates the use of statistical functions in PostgreSQL to explore risk factors and basic data analysis.

## Objectives
1. Identify demographic and clinical factors associated with cardiovascular disease.
2. Showcase useful PostgreSQL functions for statistical analysis.

## Dataset
- Original dataset: [Kaggle – Cardiovascular Disease Dataset](https://www.kaggle.com/datasets/akshatshaw7/cardiovascular-disease-dataset)
- The repo includes a 1,000-row sample CSV for testing (`data/health_data_sample.csv`).  Full dataset is 70k. We loose around 2k in cleaning outliers. 
- To use the full dataset, download the CSV from Kaggle and place it in `data/health_data.csv`.
*Version note:* We are using PostgreSQL (version 16 or higher) to ensure all statistical functions used in this project work correctly.


## Fields Description
| Field        | Description |
|--------------|------------|
| id           | Unique record identifier |
| age          | Age in days (can convert to years) |
| gender       | 0: female, 1: male |
| height       | Height in cm |
| weight       | Weight in kg |
| ap_hi        | Systolic blood pressure |
| ap_lo        | Diastolic blood pressure |
| cholesterol  | 0: normal, 1: above normal, 2: high |
| gluc         | Glucose level (0: normal, 1: above normal, 2: high) |
| smoke        | Smoker (TRUE/FALSE) |
| alco         | Alcohol consumption (TRUE/FALSE) |
| active       | Physical activity (TRUE/FALSE) |
| cardio       | Cardiovascular disease presence (TRUE/FALSE) |
| age_years       | Age but in years which. Created.|
| bmi       | Body Mass Index (BMI). Created. |

## Schema and data cleaning
- Removed physiologically implausible outliers (height, weight, blood pressure)
- Converted age from days to years (age_years)
- Derived Body Mass Index (bmi) from height and weight
- Rows removed represented a small fraction of the dataset and were excluded to prevent skewed statistical results
