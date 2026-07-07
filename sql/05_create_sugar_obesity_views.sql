DROP VIEW IF EXISTS v_sugar_obesity_country_change;
DROP VIEW IF EXISTS v_sugar_obesity_region_summary;
DROP VIEW IF EXISTS v_sugar_obesity_latest;
DROP VIEW IF EXISTS v_sugar_obesity_country_year;


-- Main joined country-year dataset.
-- This is the core dataset for the dashboard and later ML.
CREATE VIEW v_sugar_obesity_country_year AS
SELECT
    o.iso3,
    s.country,
    o.year,
    o.obesity_pct,
    o.obesity_pct_low,
    o.obesity_pct_high,
    s.sugar_supply_kg_per_capita,
    s.sugar_supply_kcal_per_capita_day,
    o.who_region,
    o.who_region_code,

    RANK() OVER (
        PARTITION BY o.year
        ORDER BY o.obesity_pct DESC
    ) AS obesity_rank_in_year,

    RANK() OVER (
        PARTITION BY o.year
        ORDER BY s.sugar_supply_kg_per_capita DESC
    ) AS sugar_rank_in_year,

    o.obesity_pct
        - LAG(o.obesity_pct) OVER (
            PARTITION BY o.iso3
            ORDER BY o.year
        ) AS obesity_change_from_previous_year,

    s.sugar_supply_kg_per_capita
        - LAG(s.sugar_supply_kg_per_capita) OVER (
            PARTITION BY o.iso3
            ORDER BY o.year
        ) AS sugar_change_from_previous_year

FROM v_obesity_country_year o
JOIN faostat_sugar_supply s
    ON o.iso3 = s.iso3
   AND o.year = s.year;


-- Latest year snapshot for dashboard cards, rankings, and map.
CREATE VIEW v_sugar_obesity_latest AS
SELECT *
FROM v_sugar_obesity_country_year
WHERE year = (
    SELECT MAX(year)
    FROM v_sugar_obesity_country_year
);


-- Regional summary by year.
-- Useful for dashboard regional comparison.
CREATE VIEW v_sugar_obesity_region_summary AS
SELECT
    who_region,
    year,
    COUNT(DISTINCT iso3) AS countries,
    AVG(obesity_pct) AS avg_obesity_pct,
    AVG(sugar_supply_kg_per_capita) AS avg_sugar_kg_per_capita,
    AVG(sugar_supply_kcal_per_capita_day) AS avg_sugar_kcal_per_capita_day,
    CORR(sugar_supply_kg_per_capita, obesity_pct) AS sugar_obesity_corr
FROM v_sugar_obesity_country_year
GROUP BY
    who_region,
    year;


-- Country-level change from first joined year to latest joined year.
CREATE VIEW v_sugar_obesity_country_change AS
WITH year_bounds AS (
    SELECT
        MIN(year) AS start_year,
        MAX(year) AS end_year
    FROM v_sugar_obesity_country_year
),

start_data AS (
    SELECT
        v.iso3,
        v.country,
        v.year AS start_year,
        v.obesity_pct AS obesity_start_pct,
        v.sugar_supply_kg_per_capita AS sugar_start_kg_per_capita
    FROM v_sugar_obesity_country_year v
    CROSS JOIN year_bounds y
    WHERE v.year = y.start_year
),

end_data AS (
    SELECT
        v.iso3,
        v.country,
        v.year AS end_year,
        v.obesity_pct AS obesity_latest_pct,
        v.sugar_supply_kg_per_capita AS sugar_latest_kg_per_capita,
        v.who_region,
        v.who_region_code
    FROM v_sugar_obesity_country_year v
    CROSS JOIN year_bounds y
    WHERE v.year = y.end_year
)

SELECT
    e.iso3,
    e.country,
    s.start_year,
    e.end_year,
    s.obesity_start_pct,
    e.obesity_latest_pct,
    e.obesity_latest_pct - s.obesity_start_pct AS obesity_change_pct_points,
    s.sugar_start_kg_per_capita,
    e.sugar_latest_kg_per_capita,
    e.sugar_latest_kg_per_capita - s.sugar_start_kg_per_capita AS sugar_change_kg_per_capita,
    e.who_region,
    e.who_region_code,

    RANK() OVER (
        ORDER BY e.obesity_latest_pct - s.obesity_start_pct DESC
    ) AS obesity_increase_rank

FROM end_data e
JOIN start_data s
    ON e.iso3 = s.iso3;