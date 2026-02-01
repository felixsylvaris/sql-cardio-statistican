# Query catalog — cardioqueries.sql

This document is a readable, annotated catalog of the queries contained in `cardioqueries.sql`. It's intended as a "code‑porn" reference for people who like to browse and understand SQL: what each query does, why it exists, and what the metric means. Data cleaning and null handling are intentionally out of scope here — see `schemaclean.md` for that — and the project README contains the narrative context.

Reference: the original SQL source is in the repository file [cardioqueries.sql](https://github.com/felixsylvaris/sql-cardio-statistican/blob/d38ee4f4459e72c6af11c1416c01836ad340ca68/cardioqueries.sql). When a query below is reproduced verbatim, the snippet header includes that source file as the origin.

---

## Table of contents

- [Counts & quick checks](#counts--quick-checks)  
- [Point-biserial correlations (screening)](#point-biserial-correlations-screening)  
- [Prevalence by categorical predictors](#prevalence-by-categorical-predictors)  
  - [Cholesterol](#cholesterol)  
  - [Gender](#gender)  
- [Basic descriptive & group summaries](#basic-descriptive--group-summaries)  
  - [Overview by disease status](#overview-by-disease-status)  
  - [Percentiles by disease status](#percentiles-by-disease-status)  
  - [Pairwise correlations (repeated view)](#pairwise-correlations-repeated-view)  
- [Clinically useful binned analyses](#clinically-useful-binned-analyses)  
  - [BMI categories](#bmi-categories)  
  - [Systolic BP staging](#systolic-bp-staging)  
  - [Age decades](#age-decades)  
  - [Two-way stratified table (BMI × SBP)](#two-way-stratified-table-bmi--sbp)  
- [Contingency-table metrics & stratified ORs](#contingency-table-metrics--stratified-ors)  
  - [Odds ratio for smoking (with continuity correction)](#odds-ratio-for-smoking-with-continuity-correction)  
  - [Mantel–Haenszel (age-stratified) OR approx](#mantelhaenszel-age-stratified-or-approx)  
- [Covariance & linear regression diagnostics](#covariance--linear-regression-diagnostics)  
  - [Covariance](#covariance)  
  - [Regression (systolic BP on predictors)](#regression-systolic-bp-on-predictors)  
- [Chi-square, grouping sets & effect-size ranking](#chi-square-grouping-sets--effect-size-ranking)  
  - [Chi-square for cholesterol vs cardio](#chi-square-for-cholesterol-vs-cardio)  
  - [Grouping sets summary (sex × cholesterol)](#grouping-sets-summary-sex--cholesterol)  
  - [Rank predictors by univariate explained variance (regr_r2)](#rank-predictors-by-univariate-explained-variance-regr_r2)  
- [Appendix: notes, caveats & small fixes](#appendix-notes-caveats--small-fixes)

---

## Counts & quick checks

Purpose: initial dataset sanity checks and to confirm sample size for downstream proportions.

```sql name=cardioqueries.sql url=https://github.com/felixsylvaris/sql-cardio-statistican/blob/d38ee4f4459e72c6af11c1416c01836ad340ca68/cardioqueries.sql
select count(*) from cardiovas;
```

What it does:
- Returns the total number of rows in the `cardiovas` table.
- Always useful to report along with any prevalence or rate.

Why it matters:
- Sample size determines precision; always show `n` alongside percentages and rates.

---

## Raw cardio values (0/1)

Purpose: inspect encoding of the target variable; confirm that `cardio` is binary and castable to integer.

```sql name=cardioqueries.sql url=https://github.com/felixsylvaris/sql-cardio-statistican/blob/d38ee4f4459e72c6af11c1416c01836ad340ca68/cardioqueries.sql
select cardio::int
from cardiovas 
order by cardio desc
;
```

What it does:
- Casts `cardio` to integer and lists values (descending).
- Good for spotting unexpected encodings like text labels or extra categories.

Recommendation:
- Replace with grouped summary for compactness:
  `SELECT cardio::int, COUNT(*) FROM cardiovas GROUP BY cardio::int ORDER BY cardio::int DESC;`

---

## Point-biserial correlations (screening)

Purpose: screen continuous variables for linear association with the binary outcome. When one variable is binary (0/1), Pearson correlation reduces to the point‑biserial correlation.

```sql name=cardioqueries.sql url=https://github.com/felixsylvaris/sql-cardio-statistican/blob/d38ee4f4459e72c6af11c1416c01836ad340ca68/cardioqueries.sql
-- We compare correlation of different values. 0.2 weak, 0.5 strong
SELECT
    CORR(cardio::int, age_years)    AS corr_age,
    CORR(cardio::int, height)       AS corr_height,
    CORR(cardio::int, weight)       AS corr_weight,
    CORR(cardio::int, ap_hi)        AS corr_systolic_bp,
    CORR(cardio::int, ap_lo)        AS corr_diastolic_bp,
    CORR(cardio::int, bmi)          AS corr_bmi,
    CORR(cardio::int, cholesterol)  AS corr_cholesterol,
    CORR(cardio::int, gluc)         AS corr_glucose,
    CORR(cardio::int, smoke)        AS corr_smoke,
    CORR(cardio::int, alco)         AS corr_alco,
    CORR(cardio::int, gender)       AS corr_gender
  FROM cardiovas;
```

What it does:
- Computes Pearson correlation between `cardio` (0/1) and each listed variable.
- Returns values in [-1, 1] indicating linear association direction and strength.

Interpretation:
- With a binary variable, this is a point-biserial correlation — useful for screening but limited: it only detects linear, monotonic relationships and is sensitive to outliers and mixed subgroups.
- Rule-of-thumb thresholds quoted in the file (0.2 weak, 0.5 strong) are only heuristics — interpret in clinical context.

Caveat:
- `gender`, `smoke`, or `alco` may be categorical/non-numeric; correlation on encoded categories can be misleading unless they are numeric encodings with meaningful ordering.

---

## Prevalence by categorical predictors

These queries compute crude prevalence (percentage with `cardio = 1`) by category.

### Cholesterol

```sql name=cardioqueries.sql url=https://github.com/felixsylvaris/sql-cardio-statistican/blob/d38ee4f4459e72c6af11c1416c01836ad340ca68/cardioqueries.sql
-- We describe disease existence by cholesterol level
SELECT cholesterol, count(*),
       ROUND(SUM(cardio::int)::numeric / COUNT(*) * 100, 2) AS disease_rate_percent
FROM cardio.cardiovas
GROUP BY cholesterol
ORDER BY cholesterol;
```

What it does:
- Groups rows by `cholesterol` category and computes count + disease percentage (rounded).

Notes:
- This is an unadjusted prevalence table — useful for reporting or exploratory comparison.
- If `cholesterol` is numeric but binned, be explicit about bin order; consider ordering by disease rate to surface high-risk bins.

### Gender

```sql name=cardioqueries.sql url=https://github.com/felixsylvaris/sql-cardio-statistican/blob/d38ee4f4459e72c6af11c1416c01836ad340ca68/cardioqueries.sql
-- We describe disease by gender
SELECT gender, count(*),
       ROUND(SUM(cardio::int)::numeric / COUNT(*) * 100, 2) AS disease_rate_percent
FROM cardio.cardiovas
GROUP BY gender
ORDER BY gender;
```

What it does:
- Same as above but stratified by `gender`.

Notes:
- Compare crude prevalence, then consider age-adjusted comparisons if age distributions differ by gender.

---

## Basic descriptive & group summaries

### Quick overview: counts and basic stats by disease status

Purpose: get counts and simple summaries (mean age, BMI for cases).

```sql name=cardioqueries.sql url=https://github.com/felixsylvaris/sql-cardio-statistican/blob/d38ee4f4459e72c6af11c1416c01836ad340ca68/cardioqueries.sql
   -- Quick overview: counts and basic stats by disease status
   -- Useful to inspect sample sizes and summary stats by cardio presence. 
    SELECT COUNT(*) AS n_total, COUNT(*) FILTER (WHERE cardio::int = 1) AS n_disease, 
    COUNT(*) FILTER (WHERE cardio::int = 0) AS n_no_disease, AVG(age_years) AS avg_age,
    AVG(bmi) FILTER (WHERE cardio::int = 1) AS avg_bmi_with_disease, STDDEV(age_years) AS sd_age 
    FROM cardiovas;
```

What it does:
- Uses FILTER to compute subgroup counts and subgroup averages.
- Good one-line summary for reports.

### Percentiles (median & quartiles) for numeric vars by cardio

Purpose: show distributional summaries (Q1, median, Q3) by outcome status.

```sql name=cardioqueries.sql url=https://github.com/felixsylvaris/sql-cardio-statistican/blob/d38ee4f4459e72c6af11c1416c01836ad340ca68/cardioqueries.sql
    --Descriptive distribution (median & quartiles) for numeric vars by cardio
    --Uses ordered-set aggregate percentile_cont to show medians/q1/q3.
    
    SELECT cardio::int AS cardio, percentile_cont(array[0.25,0.5,0.75]) WITHIN GROUP (ORDER BY age_years) AS age_qs,
    percentile_cont(array[0.25,0.5,0.75]) WITHIN GROUP (ORDER BY bmi) AS bmi_qs,
    percentile_cont(array[0.25,0.5,0.75]) WITHIN GROUP (ORDER BY ap_hi) AS ap_hi_qs
    FROM cardiovas GROUP BY cardio::int
    ORDER BY cardio::int;
```

What it does:
- `percentile_cont` returns continuous percentile estimates (interpolated) for arrays of percentiles.
- Gives a compact way to view distribution differences between cases and controls.

---

## Pairwise correlations (reiterated)

Purpose: a second, compact correlation view for a few key variables.

```sql name=cardioqueries.sql url=https://github.com/felixsylvaris/sql-cardio-statistican/blob/d38ee4f4459e72c6af11c1416c01836ad340ca68/cardioqueries.sql
   -- Pairwise correlations (quick correlation matrix)

   -- CORR demonstrates linear association between cardio (0/1) and continuous predictors. 
    SELECT CORR(cardio::int, age_years) AS corr_age, CORR(cardio::int, bmi) AS corr_bmi, 
   CORR(cardio::int, ap_hi) AS corr_systolic_bp, CORR(cardio::int, ap_lo) AS corr_diastolic_bp, 
   CORR(cardio::int, cholesterol::int)AS corr_cholesterol, CORR(cardio::int, gluc::int) AS corr_glucose,
   CORR(weight, height) AS corr_weight_height FROM cardiovas;
```

Notes:
- Correlation between weight & height is included for context (predictor inter-correlation).
- Use `NULLIF` or WHERE clauses in production to exclude invalid values.

---

## Clinically useful binned analyses

These queries convert continuous measurements into clinically interpretable bins and report disease rates.

### BMI categories

```sql name=cardioqueries.sql url=https://github.com/felixsylvaris/sql-cardio-statistican/blob/d38ee4f4459e72c6af11c1416c01836ad340ca68/cardioqueries.sql
   -- BMI categories and disease prevalence
    --Useful to show monotonic risk by BMI category. 
    SELECT CASE WHEN bmi < 18.5 THEN 'underweight'
   WHEN bmi < 25 THEN 'normal' 
   WHEN bmi < 30 THEN 'overweight'
   ELSE 'obese' END AS bmi_cat, 
   COUNT(*) AS n, SUM(cardio::int)::numeric / COUNT(*) * 100 AS disease_pct 
   FROM cardiovas GROUP BY bmi_cat 
   order by disease_pct;
```

What it does:
- Bins BMI into WHO-like categories and computes disease percentage per bin.

Why useful:
- Clinically interpretable; helpful for readers who want to see how obesity categories relate to prevalence.

### Systolic BP staging

```sql name=cardioqueries.sql url=https://github.com/felixsylvaris/sql-cardio-statistican/blob/d38ee4f4459e72c6af11c1416c01836ad340ca68/cardioqueries.sql
    --Blood-pressure staging (systolic) and disease rate
    --Define simple bp stages and check disease prevalence per stage. 
    SELECT CASE WHEN ap_hi < 120 THEN 'normal' 
    WHEN ap_hi < 130 THEN 'elevated'
    WHEN ap_hi < 140 THEN 'stage_1' ELSE 'stage_2_or_more' END AS sbp_stage,
    COUNT(*) AS n, SUM(cardio::int)::numeric / COUNT(*) * 100 AS disease_pct 
    FROM cardiovas 
    GROUP BY sbp_stage 
    ORDER BY sbp_stage;
```

What it does:
- Converts systolic pressure into simple stages and reports prevalence per stage.

Note:
- The cutpoints mimic common clinical thresholds; adjust if you want joint systolic and diastolic staging or use established guidelines.

### Age decades

```sql name=cardioqueries.sql url=https://github.com/felixsylvaris/sql-cardio-statistican/blob/d38ee4f4459e72c6af11c1416c01836ad340ca68/cardioqueries.sql
    --Age decades: trend of disease prevalence by decade
    --Good for visualizing age effect. 
    SELECT (floor(age_years/10)*10)::int AS decade_start, 
    COUNT(*) AS n, SUM(cardio::int)::numeric / COUNT(*) * 100 AS disease_pct 
    FROM cardiovas 
    GROUP BY decade_start ORDER BY decade_start;
```

What it does:
- Aggregates prevalence by decade (e.g., 20, 30, 40) — straightforward trend depiction.

---

## Two-way stratified table (BMI cat × SBP stage)

Purpose: find high-risk combined strata that may suggest interaction or target subgroups.

```sql name=cardioqueries.sql url=https://github.com/felixsylvaris/sql-cardio-statistican/blob/d38ee4f4459e72c6af11c1416c01836ad340ca68/cardioqueries.sql
    --Two-way stratified table (BMI cat × SBP stage) with disease rate using FILTER
    --Compact pivot-style view to find high-risk strata. 
    SELECT bmi_cat, sbp_stage, COUNT(*) AS n, 
    SUM(cardio::int)::numeric / NULLIF(COUNT(*),0) * 100 AS disease_pct 
    FROM ( SELECT *, CASE WHEN bmi < 25 THEN 'normal_bmi' ELSE 'high_bmi' END AS bmi_cat,
    CASE WHEN ap_hi < 130 THEN 'low_sbp' ELSE 'high_sbp' END AS sbp_stage from cardiovas ) t 
    GROUP BY bmi_cat, sbp_stage ORDER BY bmi_cat, sbp_stage;
```

What it does:
- Cross-classifies BMI (normal vs high) and SBP (low vs high) and reports prevalence per cell.
- NULLIF prevents division-by-zero for empty cells.

Why useful:
- Identifies joint strata with especially high or low disease prevalence — useful for targeted interventions or hypothesis generation.

---

## Contingency-table metrics & stratified ORs

### Odds ratio for smoking (with 0.5 continuity correction)

Purpose: compute an unadjusted odds ratio for smoking and disease, with a small correction for zero cell counts; includes 95% CI.

```sql name=cardioqueries.sql url=https://github.com/felixsylvaris/sql-cardio-statistican/blob/d38ee4f4459e72c6af11c1416c01836ad340ca68/cardioqueries.sql
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
```

Explanation:
- Builds the 2×2 table: a = exposed & case, b = exposed & control, c = unexposed & case, d = unexposed & control.
- Computes OR with 0.5 continuity correction (helps when any cell is zero).
- Computes Wald-style 95% CI on the log‑OR scale and exponentiates back.

Caveat:
- For small counts, exact methods or bootstrap may be preferred. The continuity-corrected OR is pragmatic for exploratory reporting.

### Mantel–Haenszel (age-stratified) OR approximate

Purpose: approximate an age-adjusted odds ratio for smoking by combining stratum-specific 2×2 tables (MH estimator).

```sql name=cardioqueries.sql url=https://github.com/felixsylvaris/sql-cardio-statistican/blob/d38ee4f4459e72c6af11c1416c01836ad340ca68/cardioqueries.sql
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
```

What it does:
- Implements the common MH numerator and denominator aggregation to yield a pooled OR adjusted by strata (here age decades).
- This is an approximation; robust variance and CI require additional calculations.

When to use:
- Useful when you want a quick age-adjusted OR without full logistic regression.

---

## Covariance & linear regression diagnostics

### Covariance (population & sample)

```sql name=cardioqueries.sql url=https://github.com/felixsylvaris/sql-cardio-statistican/blob/d38ee4f4459e72c6af11c1416c01836ad340ca68/cardioqueries.sql
    --Covariance and sample/population covariance
    --Use covar_pop and covar_samp. 
    SELECT COVAR_POP(age_years, bmi) AS covar_pop_age_bmi, COVAR_SAMP(age_years, bmi) AS covar_samp_age_bmi
    FROM cardiovas;
```

What it does:
- `COVAR_POP` and `COVAR_SAMP` compute population and sample covariance between age and BMI.

Why useful:
- Covariance is the numerator of Pearson correlation; it can be useful in teaching/diagnostics but is scale-dependent and less interpretable than correlation.

### Regression diagnostics (regr_* aggregates)

Purpose: produce slopes, intercepts and R^2 from simple linear regressions using built-in aggregates.

```sql name=cardioqueries.sql url=https://github.com/felixsylvaris/sql-cardio-statistican/blob/d38ee4f4459e72c6af11c1416c01836ad340ca68/cardioqueries.sql
--Regression of systolic BP on age and BMI (single-predictor examples)
--   Shows regr_slope and regr_intercept for different predictors. 
SELECT regr_slope(ap_hi, age_years) AS slope_age_on_aphi, regr_intercept(ap_hi, age_years) AS intercept_age_on_aphi, 
regr_slope(ap_hi, bmi) AS slope_bmi_on_aphi, regr_r2(ap_hi, bmi) AS r2_bmi_on_aphi 
FROM cardiovas;
```

What it does:
- `regr_slope(y, x)`, `regr_intercept(y, x)`, and `regr_r2(y, x)` compute slope, intercept, and R^2 of the linear regression of `y` on `x`.
- Here used to see how much age or BMI explain variation in systolic BP.

Notes:
- These aggregates are fast and useful for single-predictor diagnostics. For multivariable modeling (logistic regression for a binary outcome), external tools are usually preferred, but SQL stratification and MH methods can approximate adjusted estimates.

---

## Chi-square, grouping sets & effect-size ranking

### Chi-square statistic for cholesterol category vs cardio (2×k)

Purpose: compute Pearson chi-square manually for a categorical predictor with k levels.

```sql name=cardioqueries.sql url=https://github.com/felixsylvaris/sql-cardio-statistican/blob/d38ee4f4459e72c6af11c1416c01836ad340ca68/cardioqueries.sql
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
            * t.total_noncases::numeric
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
```

What it does:
- Builds observed and expected counts per category and sums the chi-square contribution.
- Manual computation is useful when you want control over grouping or to extend the math (e.g., compute effect sizes).

Note:
- (Minor fix) in the `exp` CTE above there's a variable name typo in `t.total_noncases` vs `t.total_noncases` — ensure the correct column names (`total_nocase`) if you copy this directly.

### Grouping sets for fast multi-level aggregations

Purpose: produce aggregated disease rates by sex and cholesterol at multiple grouping granularities.

```sql name=cardioqueries.sql url=https://github.com/felixsylvaris/sql-cardio-statistican/blob/d38ee4f4459e72c6af11c1416c01836ad340ca68/cardioqueries.sql
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
```

What it does:
- Returns aggregates for (sex × cholesterol), for sex alone, for cholesterol alone, and for the grand total, in a single query.
- `GROUPING SETS` is efficient and makes multi-level summary tables concise.

### Rank predictors by univariate explained variance (regr_r2)

Purpose: rank continuous predictors by the univariate R^2 when regressing the binary `cardio` (cast to numeric) on them.

```sql name=cardioqueries.sql url=https://github.com/felixsylvaris/sql-cardio-statistican/blob/d38ee4f4459e72c6af11c1416c01836ad340ca68/cardioqueries.sql
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
```

What it does:
- Uses `regr_r2` to estimate how much variance in the numeric-coded outcome (0/1) is explained by each continuous predictor in a univariate linear model.
- Ranks predictors by this simple metric to prioritize follow-up.

Caveat:
- `regr_r2` from linear regression of a binary outcome is not the same as pseudo‑R² from logistic regression; it's a pragmatic ranking tool for screening only.

---



