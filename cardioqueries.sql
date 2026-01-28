select count(*) from cardiovas;

select cardio::int
from cardiovas 
order by cardio desc
;

- We compare correlation of different values. 0.2 weak, 0.5 strong
SELECT
    CORR(cardio::int, age_years)    AS corr_age,
    CORR(cardio::int, height)       AS corr_height,
    CORR(cardio::int, weight)       AS corr_weight,
    CORR(cardio::int, ap_hi)        AS corr_systolic_bp,
    CORR(cardio::int, ap_lo)        AS corr_diastolic_bp,
    CORR(cardio::int, bmi)          AS corr_bmi,
    CORR(cardio::int, cholesterol)  AS corr_cholesterol,
    CORR(cardio::int, gluc)         AS corr_glucose,
    CORR(cardio::int, smoke)         AS corr_smoke,
    CORR(cardio::int, alco)         AS corr_alco,
    CORR(cardio::int, gender)         AS corr_gender
  FROM cardiovas;

-- We describe disease existence by cholesterol level
SELECT cholesterol, count(*),
       ROUND(SUM(cardio::int)::numeric / COUNT(*) * 100, 2) AS disease_rate_percent
FROM cardio.cardiovas
GROUP BY cholesterol
ORDER BY cholesterol;

-

-- We describe disease by gender
SELECT gender, count(*),
       ROUND(SUM(cardio::int)::numeric / COUNT(*) * 100, 2) AS disease_rate_percent
FROM cardio.cardiovas
GROUP BY gender
ORDER BY gender;


   -- Quick overview: counts and basic stats by disease status
   -- Useful to inspect sample sizes and summary stats by cardio presence. 
    SELECT COUNT(*) AS n_total, COUNT(*) FILTER (WHERE cardio::int = 1) AS n_disease, 
    COUNT(*) FILTER (WHERE cardio::int = 0) AS n_no_disease, AVG(age_years) AS avg_age,
    AVG(bmi) FILTER (WHERE cardio::int = 1) AS avg_bmi_with_disease, STDDEV(age_years) AS sd_age 
    FROM cardiovas;
   
   
    --Descriptive distribution (median & quartiles) for numeric vars by cardio
    --Uses ordered-set aggregate percentile_cont to show medians/q1/q3.
    
    SELECT cardio::int AS cardio, percentile_cont(array[0.25,0.5,0.75]) WITHIN GROUP (ORDER BY age_years) AS age_qs,
    percentile_cont(array[0.25,0.5,0.75]) WITHIN GROUP (ORDER BY bmi) AS bmi_qs,
    percentile_cont(array[0.25,0.5,0.75]) WITHIN GROUP (ORDER BY ap_hi) AS ap_hi_qs
    FROM cardiovas GROUP BY cardio::int
    ORDER BY cardio::int;


   -- Pairwise correlations (quick correlation matrix)

   -- CORR demonstrates linear association between cardio (0/1) and continuous predictors. 
    SELECT CORR(cardio::int, age_years) AS corr_age, CORR(cardio::int, bmi) AS corr_bmi, 
   CORR(cardio::int, ap_hi) AS corr_systolic_bp, CORR(cardio::int, ap_lo) AS corr_diastolic_bp, 
   CORR(cardio::int, cholesterol::int)AS corr_cholesterol, CORR(cardio::int, gluc::int) AS corr_glucose,
   CORR(weight, height) AS corr_weight_height FROM cardiovas;

   
   -- BMI categories and disease prevalence
    --Useful to show monotonic risk by BMI category. 
    SELECT CASE WHEN bmi < 18.5 THEN 'underweight'
   WHEN bmi < 25 THEN 'normal' 
   WHEN bmi < 30 THEN 'overweight'
   ELSE 'obese' END AS bmi_cat, 
   COUNT(*) AS n, SUM(cardio::int)::numeric / COUNT(*) * 100 AS disease_pct 
   FROM cardiovas GROUP BY bmi_cat 
   order by disease_pct;

   
    --Blood-pressure staging (systolic) and disease rate
    --Define simple bp stages and check disease prevalence per stage. 
    SELECT CASE WHEN ap_hi < 120 THEN 'normal' 
    WHEN ap_hi < 130 THEN 'elevated'
    WHEN ap_hi < 140 THEN 'stage_1' ELSE 'stage_2_or_more' END AS sbp_stage,
    COUNT(*) AS n, SUM(cardio::int)::numeric / COUNT(*) * 100 AS disease_pct 
    FROM cardiovas 
    GROUP BY sbp_stage 
    ORDER BY sbp_stage;
    
    
    --Age decades: trend of disease prevalence by decade
    --Good for visualizing age effect. 
    SELECT (floor(age_years/10)*10)::int AS decade_start, 
    COUNT(*) AS n, SUM(cardio::int)::numeric / COUNT(*) * 100 AS disease_pct 
    FROM cardiovas 
    GROUP BY decade_start ORDER BY decade_start;


    --Two-way stratified table (BMI cat × SBP stage) with disease rate using FILTER
    --Compact pivot-style view to find high-risk strata. 
    SELECT bmi_cat, sbp_stage, COUNT(*) AS n, 
    SUM(cardio::int)::numeric / NULLIF(COUNT(*),0) * 100 AS disease_pct 
    FROM ( SELECT *, CASE WHEN bmi < 25 THEN 'normal_bmi' ELSE 'high_bmi' END AS bmi_cat,
    CASE WHEN ap_hi < 130 THEN 'low_sbp' ELSE 'high_sbp' END AS sbp_stage from cardiovas ) t 
    GROUP BY bmi_cat, sbp_stage ORDER BY bmi_cat, sbp_stage;

    
    --Odds ratio for smoking and disease (with 0.5 continuity correction) and 95% CI
    --Demonstrates contingency-table metrics computed in SQL. 
    WITH t AS ( SELECT SUM(CASE WHEN smoke::boolean AND cardio::int = 1
    THEN 1 ELSE 0 END)::numeric AS a,
    SUM(CASE WHEN smoke::boolean AND cardio::int = 0 THEN 1
    ELSE 0 END)::numeric AS b,
    SUM(CASE WHEN NOT smoke::boolean AND cardio::int = 1 THEN 1 ELSE 0 END)::numeric AS c, 
    SUM(CASE WHEN NOT smoke::boolean AND cardio::int = 0 THEN 1 ELSE 0 END)::numeric AS d
    FROM cardiovas )
    SELECT a,b,c,d, ((a+0.5)*(d+0.5))/((b+0.5)*(c+0.5)) AS odds_ratio,
    EXP(LN(((a+0.5)*(d+0.5))/((b+0.5)*(c+0.5))) - 1.96 * SQRT(1.0/(a+0.5) + 1.0/(b+0.5) + 1.0/(c+0.5) + 1.0/(d+0.5))) AS ci_lower,
    EXP(LN(((a+0.5)*(d+0.5))/((b+0.5)*(c+0.5))) + 1.96 * SQRT(1.0/(a+0.5) + 1.0/(b+0.5) + 1.0/(c+0.5) + 1.0/(d+0.5))) AS ci_upper 
    FROM t;

    
    --Mantel–Haenszel style stratified OR (age strata)
   -- Approximate adjusted OR across age strata (implementation using counts per stratum).
    WITH strata AS ( SELECT (floor(age_years/10)*10)::int AS decade, 
    SUM(CASE WHEN smoke::boolean AND cardio::int = 1 THEN 1 ELSE 0 END) AS a, 
    SUM(CASE WHEN smoke::boolean AND cardio::int = 0 THEN 1 ELSE 0 END) AS b, 
    SUM(CASE WHEN NOT smoke::boolean AND cardio::int = 1 THEN 1 ELSE 0 END) AS c, 
    SUM(CASE WHEN NOT smoke::boolean AND cardio::int = 0 THEN 1 ELSE 0 END) AS d 
    FROM cardiovas
    GROUP BY decade ) 
    SELECT SUM(a * d / (a+b+c+d)) / SUM(b * c / (a+b+c+d)) AS mh_odds_ratio_approx FROM strata;

    
    --Covariance and sample/population covariance
    --Use covar_pop and covar_samp. 
    SELECT COVAR_POP(age_years, bmi) AS covar_pop_age_bmi, COVAR_SAMP(age_years, bmi) AS covar_samp_age_bmi
    FROM cardiovas;
    
    
    --Regression of systolic BP on age and BMI (single-predictor examples)
--   Shows regr_slope and regr_intercept for different predictors. 
SELECT regr_slope(ap_hi, age_years) AS slope_age_on_aphi, regr_intercept(ap_hi, age_years) AS intercept_age_on_aphi, 
regr_slope(ap_hi, bmi) AS slope_bmi_on_aphi, regr_r2(ap_hi, bmi) AS r2_bmi_on_aphi 
FROM cardiovas;


   -- Chi-square statistic for cholesterol category vs cardio (2×k)
    --Compute observed vs expected and chi-square manually. 
 -- Compute observed vs expected counts and chi-square statistic manually

WITH obs AS (
    SELECT
        cholesterol::text AS chol_cat,
        COUNT(*) FILTER (WHERE cardio::int = 1) AS obs_case,
        COUNT(*) FILTER (WHERE cardio::int = 0) AS obs_nocase
    FROM cardio.cardiovas
    GROUP BY cholesterol
),
totals AS (
    SELECT
        SUM(obs_case)   AS total_case,
        SUM(obs_nocase) AS total_nocase
    FROM obs
),
exp AS (
    SELECT
        o.*,
        (o.obs_case + o.obs_nocase)
            * t.total_case::numeric
            / (t.total_case + t.total_nocase) AS exp_case,
        (o.obs_case + o.obs_nocase)
            * t.total_nocase::numeric
            / (t.total_case + t.total_nocase) AS exp_nocase
    FROM obs o
    CROSS JOIN totals t
)
SELECT
    SUM(
        (obs_case   - exp_case)   ^ 2 / NULLIF(exp_case, 0) +
        (obs_nocase - exp_nocase) ^ 2 / NULLIF(exp_nocase, 0)
    ) AS chi2_stat
FROM exp;

-- Produce aggregated disease rates by different grouping combinations

SELECT
    COALESCE(gender::text, 'ALL')          AS sex,
    COALESCE(cholesterol::text, 'ALL')  AS cholesterol,
    COUNT(*)                            AS n,
    SUM(cardio::int)::numeric / COUNT(*) * 100 AS disease_pct
FROM cardio.cardiovas
GROUP BY GROUPING SETS (
    (sex, cholesterol),
    (sex),
    (cholesterol),
    ()
)
ORDER BY sex, cholesterol;

-- Compute regr_r2 of cardio::int on continuous predictors to rank predictors

SELECT
    predictor,
    r2
FROM (
    SELECT
        'age_years' AS predictor,
        regr_r2(cardio::int, age_years) AS r2
    FROM cardiovas

    UNION ALL
    SELECT
        'bmi',
        regr_r2(cardio::int, bmi)
    FROM cardiovas

    UNION ALL
    SELECT
        'ap_hi',
        regr_r2(cardio::int, ap_hi)
    FROM cardiovas

    UNION ALL
    SELECT
        'ap_lo',
        regr_r2(cardio::int, ap_lo)
    FROM cardiovas

    UNION ALL
    SELECT
        'weight',
        regr_r2(cardio::int, weight)
    FROM cardiovas
) t
ORDER BY r2 DESC NULLS LAST;


