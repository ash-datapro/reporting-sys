CREATE OR REPLACE VIEW reporting.kpi_enrollment_by_race_ethnicity AS

SELECT
    year,
    'American Indian or Alaska Native' AS race_ethnicity,
    SUM(COALESCE(american_indian_or_alaska_native_men, 0)) AS total_men,
    SUM(COALESCE(american_indian_or_alaska_native_women, 0)) AS total_women,
    SUM(
        COALESCE(american_indian_or_alaska_native_men, 0)
        + COALESCE(american_indian_or_alaska_native_women, 0)
    ) AS total_enrollment
FROM reporting.enrollment_by_demo
GROUP BY year

UNION ALL

SELECT
    year,
    'Asian' AS race_ethnicity,
    SUM(COALESCE(asian_men, 0)) AS total_men,
    SUM(COALESCE(asian_women, 0)) AS total_women,
    SUM(COALESCE(asian_men, 0) + COALESCE(asian_women, 0)) AS total_enrollment
FROM reporting.enrollment_by_demo
GROUP BY year

UNION ALL

SELECT
    year,
    'Black or African American' AS race_ethnicity,
    SUM(COALESCE(black_or_african_american_men, 0)) AS total_men,
    SUM(COALESCE(black_or_african_american_women, 0)) AS total_women,
    SUM(
        COALESCE(black_or_african_american_men, 0)
        + COALESCE(black_or_african_american_women, 0)
    ) AS total_enrollment
FROM reporting.enrollment_by_demo
GROUP BY year

UNION ALL

SELECT
    year,
    'Hispanic or Latino' AS race_ethnicity,
    SUM(COALESCE(hispanic_or_latino_men, 0)) AS total_men,
    SUM(COALESCE(hispanic_or_latino_women, 0)) AS total_women,
    SUM(COALESCE(hispanic_or_latino_men, 0) + COALESCE(hispanic_or_latino_women, 0)) AS total_enrollment
FROM reporting.enrollment_by_demo
GROUP BY year

UNION ALL

SELECT
    year,
    'Native Hawaiian or Other Pacific Islander' AS race_ethnicity,
    SUM(COALESCE(native_hawaiian_or_other_pacific_islander_men, 0)) AS total_men,
    SUM(COALESCE(native_hawaiian_or_other_pacific_islander_women, 0)) AS total_women,
    SUM(
        COALESCE(native_hawaiian_or_other_pacific_islander_men, 0)
        + COALESCE(native_hawaiian_or_other_pacific_islander_women, 0)
    ) AS total_enrollment
FROM reporting.enrollment_by_demo
GROUP BY year

UNION ALL

SELECT
    year,
    'White' AS race_ethnicity,
    SUM(COALESCE(white_men, 0)) AS total_men,
    SUM(COALESCE(white_women, 0)) AS total_women,
    SUM(COALESCE(white_men, 0) + COALESCE(white_women, 0)) AS total_enrollment
FROM reporting.enrollment_by_demo
GROUP BY year

UNION ALL

SELECT
    year,
    'Two or More Races' AS race_ethnicity,
    SUM(COALESCE(two_or_more_races_men, 0)) AS total_men,
    SUM(COALESCE(two_or_more_races_women, 0)) AS total_women,
    SUM(COALESCE(two_or_more_races_men, 0) + COALESCE(two_or_more_races_women, 0)) AS total_enrollment
FROM reporting.enrollment_by_demo
GROUP BY year

UNION ALL

SELECT
    year,
    'Race/Ethnicity Unknown' AS race_ethnicity,
    SUM(COALESCE(race_ethnicity_unknown_men, 0)) AS total_men,
    SUM(COALESCE(race_ethnicity_unknown_women, 0)) AS total_women,
    SUM(
        COALESCE(race_ethnicity_unknown_men, 0)
        + COALESCE(race_ethnicity_unknown_women, 0)
    ) AS total_enrollment
FROM reporting.enrollment_by_demo
GROUP BY year

UNION ALL

SELECT
    year,
    'Nonresident' AS race_ethnicity,
    SUM(COALESCE(nonresident_men, 0)) AS total_men,
    SUM(COALESCE(nonresident_women, 0)) AS total_women,
    SUM(COALESCE(nonresident_men, 0) + COALESCE(nonresident_women, 0)) AS total_enrollment
FROM reporting.enrollment_by_demo
GROUP BY year;

SELECT *
FROM reporting.kpi_enrollment_by_race_ethnicity
ORDER BY year, total_enrollment DESC;