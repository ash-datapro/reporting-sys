CREATE OR REPLACE VIEW reporting.kpi_enrollment_race_ethnicity_share AS
WITH race_totals AS (
    SELECT *
    FROM reporting.kpi_enrollment_by_race_ethnicity
),

year_totals AS (
    SELECT
        year,
        SUM(total_enrollment) AS year_total_enrollment
    FROM race_totals
    GROUP BY year
)

SELECT
    rt.year,
    rt.race_ethnicity,
    rt.total_men,
    rt.total_women,
    rt.total_enrollment,
    ROUND(
        100.0 * rt.total_enrollment / NULLIF(yt.year_total_enrollment, 0),
        1
    ) AS pct_of_enrollment
FROM race_totals rt
JOIN year_totals yt
    ON rt.year = yt.year
ORDER BY
    rt.year,
    rt.total_enrollment DESC;

SELECT *
FROM reporting.kpi_enrollment_race_ethnicity_share;