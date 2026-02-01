# Cardiovascular Disease Analysis in PostgreSQL

This project analyzes a cardiovascular disease dataset and demonstrates the use of statistical and analytical functions available in PostgreSQL to explore factors associated with cardiovascular disease.

## Objectives
1. Identify demographic and clinical factors associated with cardiovascular disease.
2. Showcase useful PostgreSQL functions for statistical analysis.

## Dataset
- Original dataset: [Kaggle – Cardiovascular Disease Dataset](https://www.kaggle.com/datasets/akshatshaw7/cardiovascular-disease-dataset)
- The repository includes a 1,000-row sample CSV for testing(`data/health_data_sample.csv`).
- The full dataset contains approximately 70,000 records. Around 2,000 rows were removed during data cleaning due to physiologically implausible values. 
- To use the full dataset, download the CSV from Kaggle and place it in `data/health_data.csv`.
*Version note:* PostgreSQL version 16 or higher is used to ensure compatibility with all statistical functions applied in this project.


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

Detailed cleaning steps are documented separately in cardioschema.sql and shema.md .

## Results
- Overall correlations between individual variables and cardiovascular disease were generally modest, with all coefficients remaining below 0.5. Height, glucose level, gender, alcohol consumption, and physical activity showed correlations close to zero, indicating negligible linear association with disease presence. Gender in particular did not exhibit a meaningful relationship and was therefore not treated as a stratification factor in further analyses.
- Both systolic and diastolic blood pressure showed moderate positive correlations with cardiovascular disease (approximately 0.4). While these associations are notable, they may partially reflect disease-related physiological changes rather than purely predisposing risk factors, given the cross-sectional nature of the dataset.
- Age, body mass index (BMI), and cholesterol level demonstrated weak but positive correlations (approximately 0.2) with cardiovascular disease, suggesting incremental contributions to disease risk when considered individually.
- Disease prevalence increased substantially across cholesterol categories, with approximately 75% of respondents in the highest cholesterol group exhibiting cardiovascular disease.
- The age distribution of the dataset spans approximately 30 to 65 years, representing a subset of adult life. Given that the average life expectancy in the United States is approximately 79 years, this age restriction introduces bias that may attenuate the observed influence of age on disease prevalence.
- Despite this limitation, notable differences were observed across age groups: respondents aged 30–40 showed cardiovascular disease in approximately 24% of cases (based on a smaller sample of roughly 1,700 observations), while those aged 60 and above exhibited disease prevalence approaching 66%.
- A clear gradient was also observed across BMI categories. Individuals with BMI below 25 (normal range) showed disease prevalence around 40%, whereas respondents with BMI above 30 (obese range) exhibited cardiovascular disease in more than 60% of cases.
- Systolic blood pressure showed a stronger association with cardiovascular disease than diastolic pressure in this dataset. Diastolic blood pressure was also positively correlated with disease presence, though with lower magnitude. This pattern is consistent with clinical literature, where systolic hypertension is often a stronger risk indicator in adult populations, while diastolic pressure still contributes to overall cardiovascular risk.
- Single-predictor linear models further supported these findings. The relative explanatory strength of individual variables followed the order: systolic blood pressure (ap_hi) > diastolic blood pressure (ap_lo) > cholesterol > age > BMI > weight. Only systolic and diastolic blood pressure explained more than 10% of variance individually, reinforcing the dominant role of blood pressure–related measures. These results were consistent with correlation and stratified prevalence analyses.

##Queries and Analysis
- SQL queries used for analysis are provided in cardioqueries.sql .
- Additional explanations and selected outputs are documented in querries.md .
