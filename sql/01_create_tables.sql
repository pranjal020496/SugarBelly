DROP TABLE IF EXISTS who_obesity;

CREATE TABLE who_obesity (
    iso3 CHAR(3) NOT NULL,
    year INT NOT NULL,
    sex TEXT NOT NULL,
    sex_code TEXT NOT NULL,
    obesity_pct NUMERIC,
    obesity_pct_low NUMERIC,
    obesity_pct_high NUMERIC,
    who_region TEXT,
    who_region_code TEXT,
    PRIMARY KEY (iso3, year, sex_code)
);