# Query catalog — cardioqueries.sql

This file documents and explains the SQL queries in `cardioqueries.sql`. It assumes data cleaning and null handling are done in your separate schema-cleaning files and that the project README contains the high-level narrative. This document is meant as "code porn" for people who like readable, annotated queries: what each query does, why it’s useful, and what the metric means.

---

## Table of contents
- [Count rows](#count-rows)
- [Raw cardio values (0/1)](#raw-cardio-values-01)
- [Correlation matrix (cardio vs continuous features)](#correlation-matrix-cardio-vs-continuous-features)
- [Disease rate by cholesterol category](#disease-rate-by-cholesterol-category)
- [Notes & small improvements](#notes--small-improvements)

---

## Count rows

Purpose: quick sanity check — how many records are present in the cleaned table.

```sql
select count(*) from cardiovas;
```

What this does:
- Returns number of rows in the `cardiovas` table.
- Useful as a first step to confirm the dataset loaded correctly and to show sample size for any downstream proportions or statistical estimates.

Why it's useful:
- Sample size directly affects confidence in estimates; always report counts alongside rates.

---

## Raw cardio values (0/1)

Purpose: inspect the stored `cardio` variable and verify encoding when casting to integer.

```sql
select cardio::int
from cardiovas 
order by cardio desc
;
```

What this does:
- Casts `cardio` to integer (`cardio::int`) and lists values ordered descending.
- If `cardio` is boolean or textual ("0"/"1"), casting to integer yields 0/1 numeric values.

Why it's useful:
- Quick visual check of the values and their ordering; helps detect unexpected encodings (e.g., `NULL`, `-1`, or text labels).
- For programmatic analysis, the binary 0/1 numeric form is convenient for aggregate functions (AVG, SUM) and correlation.

Suggestion:
- For a compact summary prefer `SELECT cardio::int, count(*) FROM cardiovas GROUP BY cardio::int ORDER BY cardio::int DESC;` to get counts per value.

---

## Correlation matrix (cardio vs continuous features)

Purpose: compute pairwise Pearson correlations between `cardio` (cast to 0/1) and continuous predictors to screen for linear associations.

```sql
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
    CORR(cardio::int, bmi)          AS corr_bmi
FROM cardiovas;
```

What this does:
- Uses PostgreSQL's aggregate `corr(x,y)` (Pearson correlation) to measure linear association between `cardio` (0/1) and numeric variables.
- The value range is [-1, 1]; values near 0 indicate little linear association; values near ±1 indicate strong linear association.

Interpretation notes:
- When one variable is binary (0/1), `CORR(cardio::int, continuous_var)` is the point-biserial correlation — a special case of Pearson correlation appropriate for a binary & continuous pair.
- Rough guidance (context dependent): |r| ≈ 0.1 small, 0.3 moderate, 0.5 large — but clinical importance depends on effect size and prevalence.

Important observations:
- The query contains `CORR(cardio::int, bmi)` twice (duplicate alias `corr_bmi`). Remove the duplicate to avoid confusion.
- Correlation measures only linear association and does not imply causation.
- Correlation can be attenuated by nonlinearity, outliers, or heterogeneous subgroups — follow up strong or surprising correlations with stratified analysis or visualization.

Suggested additions:
- Add `FILTER` or `WHERE` to exclude extreme/invalid values prior to correlation (e.g., implausible bp or BMI values).
- Consider `regr_r2` or logistic models for more interpretive effect sizes.

---

## Disease rate by cholesterol category

Purpose: summarize prevalence of the outcome (`cardio`) across levels of the categorical predictor `cholesterol`.

```sql
-- We describe disease existence by cholesterol level
SELECT cholesterol, count(*),
       ROUND(SUM(cardio::int)::numeric / COUNT(*) * 100, 2) AS disease_rate_percent
FROM cardio.cardiovas
GROUP BY cholesterol
ORDER BY cholesterol;
```

What this does:
- Groups rows by cholesterol category and computes:
  - the count of rows in each category
  - `disease_rate_percent`: proportion of records with `cardio = 1` converted to a percentage (rounded to two decimals).

Interpretation notes:
- This is a direct, unadjusted prevalence by cholesterol level. It’s useful to show crude differences but does not adjust for confounders (age, sex, BMI, BP).
- Good for tables and initial reporting; follow with statistical tests (chi-square) or adjusted analyses for inference.

Important observations and cautions:
- The query references `cardio.cardiovas` (schema-qualified) while other queries refer to `cardiovas` (no schema). Use consistent identifiers: either `cardiovas` or `schema.table`.
- If there are categories with zero rows, `COUNT(*)` will be 0 and division by zero must be avoided — though GROUP BY prevents zero counts from appearing. If working with generated bins, use `NULLIF(COUNT(*),0)` to be safe.
- If `cholesterol` is numeric but intended as ordered categories, casting to text or ordering by numeric value may be preferred.

Suggested extensions:
- Order results by `disease_rate_percent DESC` to surface highest-risk categories.
- Add confidence intervals for each percentage (e.g., Wilson interval) when sample sizes are small.
- Consider logistic regression or Mantel–Haenszel stratification for adjusted comparisons.

---

## Notes & small improvements

- Consistency: choose a single table reference (`cardiovas` or `cardio.cardiovas`) across the file to avoid confusion.
- Duplicate line: remove the duplicate `corr_bmi` entry in the correlation query.
- Defensive coding: when dividing by counts, prefer `NULLIF(COUNT(*), 0)` to avoid division-by-zero errors when building derived bins or outer joins.
- Casting: `cardio::int` is convenient and explicit; ensure `cardio` values are consistent (booleans or text "0"/"1"). If `cardio` can be non-binary, validate values first.
- Follow-up analyses often needed: correlation is useful for screening but should be supplemented with stratified analysis, adjusted (multivariable) models, or contingency-table inference as appropriate for the project goals.
- Documentation: cross-link queries.md to `schemaclean.md` and `README.md` so readers know where to find data preparation steps and the project narrative.

---

If you want, I can:
- Fix the small issues (schema consistency and duplicate `corr_bmi`) and produce an updated `cardioqueries.sql`.
- Convert selected queries into saved views or SQL functions for reproducible reporting.
- Add small examples showing how to produce confidence intervals for the disease rates in SQL.

True mastery is from reduction — I kept the explanations focused and actionable. Let me know what you want next.