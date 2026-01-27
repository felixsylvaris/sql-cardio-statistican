select count(*) from cardiovas;

select cardio::int
from cardiovas 
order by cardio desc
;

-- We describe disease existence by cholesterol level
SELECT cholesterol, count(*),
       ROUND(SUM(cardio::int)::numeric / COUNT(*) * 100, 2) AS disease_rate_percent
FROM cardio.cardiovas
GROUP BY cholesterol
ORDER BY cholesterol;

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
     CORR(cardio::int, bmi)         AS corr_bmi
FROM cardiovas;

