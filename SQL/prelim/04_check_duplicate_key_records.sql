SELECT
    year,
    level_of_award,
    gender,
    COUNT(*) AS record_count
FROM raw.awards_by_demo
GROUP BY
    year,
    level_of_award,
    gender
HAVING COUNT(*) > 1;

SELECT
    year,
    state_or_jurisdiction,
    COUNT(*) AS record_count
FROM raw.enrollment_by_demo
GROUP BY
    year,
    state_or_jurisdiction
HAVING COUNT(*) > 1;

SELECT
    year,
    level_of_institution,
    distance_education_status_of_student,
    COUNT(*) AS record_count
FROM raw.enrollment_by_level
GROUP BY
    year,
    level_of_institution,
    distance_education_status_of_student
HAVING COUNT(*) > 1;

SELECT
    year,
    level_of_institution,
    type_of_aid_awarded,
    family_income_level,
    COUNT(*) AS record_count
FROM raw.financial_aid
GROUP BY
    year,
    level_of_institution,
    type_of_aid_awarded,
    family_income_level
HAVING COUNT(*) > 1;

SELECT
    year,
    level_of_institution,
    control_of_institution,
    gender,
    COUNT(*) AS record_count
FROM raw.graduation_rates
GROUP BY
    year,
    level_of_institution,
    control_of_institution,
    gender
HAVING COUNT(*) > 1;

SELECT
    year,
    level_of_institution,
    degree_granting_status,
    control_of_institution,
    enrollment_status,
    COUNT(*) AS record_count
FROM raw.retention_undergrad
GROUP BY
    year,
    level_of_institution,
    degree_granting_status,
    control_of_institution,
    enrollment_status
HAVING COUNT(*) > 1;
