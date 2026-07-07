-- 1. Check row count by sex
SELECT
    sex,
    COUNT(*) AS row_count,
    MIN(year) AS min_year,
    MAX(year) AS max_year
FROM who_obesity
GROUP BY sex
ORDER BY sex;


-- 2. Top 10 countries by obesity prevalence in 2024
SELECT
    iso3,
    ROUND(obesity_pct, 2) AS obesity_pct,
    who_region
FROM who_obesity
WHERE year = 2024
  AND sex = 'Both sexes'
ORDER BY obesity_pct DESC
LIMIT 10;


-- 3. Obesity trend for Germany
SELECT
    year,
    ROUND(obesity_pct, 2) AS obesity_pct
FROM who_obesity
WHERE iso3 = 'DEU'
  AND sex = 'Both sexes'
ORDER BY year;


-- 4. Average obesity by WHO region in 2024
SELECT
    who_region,
    ROUND(AVG(obesity_pct), 2) AS avg_obesity_pct
FROM who_obesity
WHERE year = 2024
  AND sex = 'Both sexes'
GROUP BY who_region
ORDER BY avg_obesity_pct DESC;


-- 5. Countries with largest obesity increase from 1980 to 2024
WITH obesity_1980 AS (
    SELECT
        iso3,
        obesity_pct AS obesity_1980
    FROM who_obesity
    WHERE year = 1980
      AND sex = 'Both sexes'
),
obesity_2024 AS (
    SELECT
        iso3,
        obesity_pct AS obesity_2024
    FROM who_obesity
    WHERE year = 2024
      AND sex = 'Both sexes'
)
SELECT
    o24.iso3,
    ROUND(o80.obesity_1980, 2) AS obesity_1980,
    ROUND(o24.obesity_2024, 2) AS obesity_2024,
    ROUND(o24.obesity_2024 - o80.obesity_1980, 2) AS obesity_increase
FROM obesity_2024 o24
JOIN obesity_1980 o80
    ON o24.iso3 = o80.iso3
ORDER BY obesity_increase DESC
LIMIT 10;