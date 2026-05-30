CREATE OR REPLACE VIEW reporting.kpi_distance_status_share_by_year AS
WITH distance_totals AS (
    SELECT
        year,
        distance_education_status_of_student,
        SUM(
            COALESCE(total_undergraduate, 0)
            + COALESCE(total_graduate, 0)
        ) AS total_enrollment
    FROM reporting.enrollment_by_level
    GROUP BY
        year,
        distance_education_status_of_student
),

year_totals AS (
    SELECT
        year,
        SUM(total_enrollment) AS year_total_enrollment
    FROM distance_totals
    GROUP BY year
)

SELECT
    dt.year,
    dt.distance_education_status_of_student,
    dt.total_enrollment,
    ROUND(
        100.0 * dt.total_enrollment / NULLIF(yt.year_total_enrollment, 0),
        1
    ) AS pct_of_enrollment
FROM distance_totals dt
JOIN year_totals yt
    ON dt.year = yt.year
ORDER BY
    dt.year,
    dt.total_enrollment DESC;

SELECT *
FROM reporting.kpi_distance_status_share_by_year;