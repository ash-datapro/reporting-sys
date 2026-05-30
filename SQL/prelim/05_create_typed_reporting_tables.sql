DROP TABLE IF EXISTS reporting.awards_by_demo;

CREATE TABLE reporting.awards_by_demo AS
SELECT *
FROM raw.awards_by_demo;

ALTER TABLE reporting.awards_by_demo
ADD CONSTRAINT pk_awards_by_demo
PRIMARY KEY (
    year,
    level_of_award,
    gender
);

DROP TABLE IF EXISTS reporting.enrollment_by_demo;

CREATE TABLE reporting.enrollment_by_demo AS
SELECT *
FROM raw.enrollment_by_demo;

ALTER TABLE reporting.enrollment_by_demo
ADD CONSTRAINT pk_enrollment_by_demo
PRIMARY KEY (
    year,
    state_or_jurisdiction
);

DROP TABLE IF EXISTS reporting.enrollment_by_level;

CREATE TABLE reporting.enrollment_by_level AS
SELECT *
FROM raw.enrollment_by_level;

ALTER TABLE reporting.enrollment_by_level
ADD CONSTRAINT pk_enrollment_by_level
PRIMARY KEY (
    year,
    level_of_institution,
    distance_education_status_of_student
);

DROP TABLE IF EXISTS reporting.financial_aid;

CREATE TABLE reporting.financial_aid AS
SELECT *
FROM raw.financial_aid;

ALTER TABLE reporting.financial_aid
ALTER COLUMN private_nonprofit_average_grant_scholarship_aid TYPE NUMERIC
USING private_nonprofit_average_grant_scholarship_aid::NUMERIC,
ALTER COLUMN private_nonprofit_average_grant_scholarship_aid DROP NOT NULL;

ALTER TABLE reporting.financial_aid
ALTER COLUMN private_nonprofit_net_price TYPE NUMERIC
USING private_nonprofit_net_price::NUMERIC,
ALTER COLUMN private_nonprofit_net_price DROP NOT NULL;

ALTER TABLE reporting.financial_aid
ADD CONSTRAINT pk_financial_aid
PRIMARY KEY (
    year,
    level_of_institution,
    type_of_aid_awarded,
    family_income_level
);

DROP TABLE IF EXISTS reporting.graduation_rates;

CREATE TABLE reporting.graduation_rates AS
SELECT *
FROM raw.graduation_rates;

ALTER TABLE reporting.graduation_rates
ALTER COLUMN american_indian_or_alaska_native TYPE NUMERIC
USING american_indian_or_alaska_native::NUMERIC,
ALTER COLUMN american_indian_or_alaska_native DROP NOT NULL;

ALTER TABLE reporting.graduation_rates
ALTER COLUMN asian TYPE NUMERIC
USING asian::NUMERIC,
ALTER COLUMN asian DROP NOT NULL;

ALTER TABLE reporting.graduation_rates
ALTER COLUMN black_or_african_american TYPE NUMERIC
USING black_or_african_american::NUMERIC,
ALTER COLUMN black_or_african_american DROP NOT NULL;

ALTER TABLE reporting.graduation_rates
ALTER COLUMN hispanic_or_latino TYPE NUMERIC
USING hispanic_or_latino::NUMERIC,
ALTER COLUMN hispanic_or_latino DROP NOT NULL;

ALTER TABLE reporting.graduation_rates
ALTER COLUMN native_hawaiian_or_other_pacific_islander TYPE NUMERIC
USING native_hawaiian_or_other_pacific_islander::NUMERIC,
ALTER COLUMN native_hawaiian_or_other_pacific_islander DROP NOT NULL;

ALTER TABLE reporting.graduation_rates
ALTER COLUMN white TYPE NUMERIC
USING white::NUMERIC,
ALTER COLUMN white DROP NOT NULL;

ALTER TABLE reporting.graduation_rates
ALTER COLUMN two_or_more_races TYPE NUMERIC
USING two_or_more_races::NUMERIC,
ALTER COLUMN two_or_more_races DROP NOT NULL;

ALTER TABLE reporting.graduation_rates
ALTER COLUMN race_ethnicity_unknown TYPE NUMERIC
USING race_ethnicity_unknown::NUMERIC,
ALTER COLUMN race_ethnicity_unknown DROP NOT NULL;

ALTER TABLE reporting.graduation_rates
ALTER COLUMN nonresident TYPE NUMERIC
USING nonresident::NUMERIC,
ALTER COLUMN nonresident DROP NOT NULL;

ALTER TABLE reporting.graduation_rates
ALTER COLUMN level_of_institution_footnote TYPE TEXT,
ALTER COLUMN level_of_institution_footnote DROP NOT NULL;

ALTER TABLE reporting.graduation_rates
ADD CONSTRAINT pk_graduation_rates
PRIMARY KEY (
    year,
    level_of_institution,
    control_of_institution,
    gender
);

DROP TABLE IF EXISTS reporting.retention_undergrad;

CREATE TABLE reporting.retention_undergrad AS
SELECT *
FROM raw.retention_undergrad;

ALTER TABLE reporting.retention_undergrad
ADD CONSTRAINT pk_retention_undergrad
PRIMARY KEY (
    year,
    level_of_institution,
    degree_granting_status,
    control_of_institution,
    enrollment_status
);
