-- ============================================================
-- 03_borrower_and_geographic_analysis.sql
-- California HMDA 2024
-- Borrower characteristics, pricing, and geographic analysis
-- ============================================================

-- ============================================================
-- DTI Analysis
-- ============================================================
WITH decisioned AS (
    SELECT *
    FROM read_parquet('data/processed/hmda_ca_2024_cleaned.parquet')
    WHERE action_taken IN (1, 2, 3)
)

SELECT
    COUNT(*) AS total_decisioned,
    COUNT(debt_to_income_ratio) AS dti_available
FROM decisioned;



WITH decisioned AS (
    SELECT *
    FROM read_parquet('data/processed/hmda_ca_2024_cleaned.parquet')
    WHERE action_taken IN (1, 2, 3)
),

dti_grouped AS (
    SELECT
        *,
        CASE
             WHEN debt_to_income_ratio = '<20%' THEN '<20%'
        WHEN debt_to_income_ratio = '20%-<30%' THEN '20%-<30%'
        WHEN debt_to_income_ratio = '30%-<36%' THEN '30%-<36%'

        WHEN TRY_CAST(debt_to_income_ratio AS DOUBLE)
             BETWEEN 36 AND 39 THEN '36%-<40%'

        WHEN TRY_CAST(debt_to_income_ratio AS DOUBLE)
             BETWEEN 40 AND 44 THEN '40%-<45%'

        WHEN TRY_CAST(debt_to_income_ratio AS DOUBLE)
             BETWEEN 45 AND 49 THEN '45%-<50%'

        WHEN debt_to_income_ratio = '50%-60%' THEN '50%-60%'
        WHEN debt_to_income_ratio = '>60%' THEN '>60%'
        WHEN debt_to_income_ratio = 'Exempt' THEN 'Exempt'
        END AS dti_group
    FROM decisioned
)

SELECT
    dti_group,
    COUNT(*) AS applications,
    SUM(CASE WHEN action_taken IN (1, 2) THEN 1 ELSE 0 END) AS approved,
    SUM(CASE WHEN action_taken = 3 THEN 1 ELSE 0 END) AS denied,
    ROUND(
        100.0 * SUM(CASE WHEN action_taken IN (1, 2) THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS approval_rate_pct
FROM dti_grouped
WHERE dti_group IS NOT NULL
GROUP BY dti_group
ORDER BY
    CASE dti_group
        WHEN '<20%' THEN 1
        WHEN '20%-<30%' THEN 2
        WHEN '30%-<36%' THEN 3
        WHEN '36%-<40%' THEN 4
        WHEN '40%-<45%' THEN 5
        WHEN '45%-<50%' THEN 6
        WHEN '50%-60%' THEN 7
        WHEN '>60%' THEN 8
        WHEN 'Exempt' THEN 9
    END;



-- ============================================================
-- Income Analysis
-- ============================================================

SELECT
    COUNT(*) AS total_applications,
    COUNT(income) AS income_available,
    MIN(income) AS min_income,
    MAX(income) AS max_income
FROM read_parquet('data/processed/hmda_ca_2024_cleaned.parquet')
WHERE action_taken IN (1, 2, 3);


SELECT
    ROUND(AVG(income), 2) AS avg_income,
    MEDIAN(income) AS median_income,
    QUANTILE_CONT(income, 0.25) AS p25_income,
    QUANTILE_CONT(income, 0.75) AS p75_income,
    QUANTILE_CONT(income, 0.95) AS p95_income,
    QUANTILE_CONT(income, 0.99) AS p99_income
FROM read_parquet('data/processed/hmda_ca_2024_cleaned.parquet')
WHERE action_taken IN (1, 2, 3)
  AND income IS NOT NULL;



WITH decisioned AS (
    SELECT *
    FROM read_parquet('data/processed/hmda_ca_2024_cleaned.parquet')
    WHERE action_taken IN (1, 2, 3)
)

SELECT
    CASE
        WHEN action_taken IN (1, 2) THEN 'Approved'
        WHEN action_taken = 3 THEN 'Denied'
    END AS decision_outcome,

    COUNT(income) AS income_available,

    ROUND(MEDIAN(income), 2) AS median_income,

    ROUND(AVG(income), 2) AS avg_income

FROM decisioned
WHERE income IS NOT NULL
GROUP BY decision_outcome;


WITH decisioned AS (
    SELECT *
    FROM read_parquet('data/processed/hmda_ca_2024_cleaned.parquet')
    WHERE action_taken IN (1, 2, 3)
),

income_grouped AS (
    SELECT
        *,
        CASE
            WHEN income <= 0 THEN 'Non-positive'
            WHEN income > 0 AND income < 50 THEN '<$50K'
            WHEN income >= 50 AND income < 100 THEN '$50K-<$100K'
            WHEN income >= 100 AND income < 150 THEN '$100K-<$150K'
            WHEN income >= 150 AND income < 250 THEN '$150K-<$250K'
            WHEN income >= 250 AND income < 500 THEN '$250K-<$500K'
            WHEN income >= 500 THEN '$500K+'
        END AS income_group
    FROM decisioned
)

SELECT
    income_group,
    COUNT(*) AS applications,
    SUM(CASE WHEN action_taken IN (1, 2) THEN 1 ELSE 0 END) AS approved,
    SUM(CASE WHEN action_taken = 3 THEN 1 ELSE 0 END) AS denied,
    ROUND(
        100.0 * SUM(CASE WHEN action_taken IN (1, 2) THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS approval_rate_pct
FROM income_grouped
WHERE income_group IS NOT NULL
GROUP BY income_group
ORDER BY
    CASE income_group
        WHEN 'Non-positive' THEN 1
        WHEN '<$50K' THEN 2
        WHEN '$50K-<$100K' THEN 3
        WHEN '$100K-<$150K' THEN 4
        WHEN '$150K-<$250K' THEN 5
        WHEN '$250K-<$500K' THEN 6
        WHEN '$500K+' THEN 7
    END;



-- ============================================================
-- LTV Analysis
-- ============================================================
SELECT
    COUNT(*) AS total_rows,
    COUNT(loan_to_value_ratio) AS ltv_available,
    COUNT(*) - COUNT(loan_to_value_ratio) AS ltv_missing,
    MIN(loan_to_value_ratio) AS min_ltv,
    MAX(loan_to_value_ratio) AS max_ltv
FROM read_parquet('data/processed/hmda_ca_2024_cleaned.parquet')
WHERE action_taken IN (1, 2, 3);


SELECT
    MEDIAN(loan_to_value_ratio) AS median_ltv,
    QUANTILE_CONT(loan_to_value_ratio, 0.25) AS p25_ltv,
    QUANTILE_CONT(loan_to_value_ratio, 0.75) AS p75_ltv,
    QUANTILE_CONT(loan_to_value_ratio, 0.95) AS p95_ltv,
    QUANTILE_CONT(loan_to_value_ratio, 0.99) AS p99_ltv
FROM read_parquet('data/processed/hmda_ca_2024_cleaned.parquet')
WHERE action_taken IN (1, 2, 3)
  AND loan_to_value_ratio IS NOT NULL;



SELECT
    COUNT(*) AS ltv_over_200
FROM read_parquet('data/processed/hmda_ca_2024_cleaned.parquet')
WHERE action_taken IN (1, 2, 3)
  AND loan_to_value_ratio > 200;




WITH decisioned AS (
    SELECT *
    FROM read_parquet('data/processed/hmda_ca_2024_cleaned.parquet')
    WHERE action_taken IN (1, 2, 3)
),

ltv_grouped AS (
    SELECT
    *,
    CASE
    WHEN loan_to_value_ratio < 50 THEN '<50%'

    WHEN loan_to_value_ratio >= 50
         AND loan_to_value_ratio < 60
    THEN '50%-<60%'

    WHEN loan_to_value_ratio >= 60
         AND loan_to_value_ratio < 70
    THEN '60%-<70%'

    WHEN loan_to_value_ratio >= 70
         AND loan_to_value_ratio < 80
    THEN '70%-<80%'

    WHEN loan_to_value_ratio >= 80
         AND loan_to_value_ratio < 90
    THEN '80%-<90%'

    WHEN loan_to_value_ratio >= 90
         AND loan_to_value_ratio < 100
    THEN '90%-<100%'

    WHEN loan_to_value_ratio >= 100
         AND loan_to_value_ratio <= 200
    THEN '100%-200%'

    WHEN loan_to_value_ratio > 200
    THEN 'Extreme >200%'
END AS ltv_group
FROM decisioned
)

SELECT
    ltv_group,
    COUNT(*) AS applications,
    SUM(CASE WHEN action_taken IN (1, 2) THEN 1 ELSE 0 END) AS approved,
    SUM(CASE WHEN action_taken = 3 THEN 1 ELSE 0 END) AS denied,
    ROUND(
        100.0 * SUM(CASE WHEN action_taken IN (1, 2) THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS approval_rate_pct
FROM ltv_grouped
WHERE ltv_group IS NOT NULL
GROUP BY ltv_group
ORDER BY
    CASE ltv_group
        WHEN '<50%' THEN 1
        WHEN '50%-<60%' THEN 2
        WHEN '60%-<70%' THEN 3
        WHEN '70%-<80%' THEN 4
        WHEN '80%-<90%' THEN 5
        WHEN '90%-<100%' THEN 6
        WHEN '100%-200%' THEN 7
        WHEN 'Extreme >200%' THEN 8
    END;



-- ============================================================
-- Interest Rate Analysis
-- ============================================================
SELECT
    COUNT(*) AS total_rows,
    COUNT(interest_rate) AS rate_available,
    COUNT(*) - COUNT(interest_rate) AS rate_missing,
    MIN(interest_rate) AS min_rate,
    MAX(interest_rate) AS max_rate
FROM read_parquet('data/processed/hmda_ca_2024_cleaned.parquet')
WHERE action_taken IN (1, 2, 3);


SELECT
    ROUND(AVG(interest_rate), 3) AS avg_rate,
    ROUND(MEDIAN(interest_rate), 3) AS median_rate,
    ROUND(QUANTILE_CONT(interest_rate, 0.25), 3) AS p25_rate,
    ROUND(QUANTILE_CONT(interest_rate, 0.75), 3) AS p75_rate,
    ROUND(QUANTILE_CONT(interest_rate, 0.95), 3) AS p95_rate,
    ROUND(QUANTILE_CONT(interest_rate, 0.99), 3) AS p99_rate
FROM read_parquet('data/processed/hmda_ca_2024_cleaned.parquet')
WHERE action_taken IN (1, 2, 3)
  AND interest_rate IS NOT NULL;


SELECT
    CASE
        WHEN action_taken IN (1, 2) THEN 'Approved'
        WHEN action_taken = 3 THEN 'Denied'
    END AS decision_outcome,

    COUNT(*) AS applications,
    COUNT(interest_rate) AS rate_available,
    COUNT(*) - COUNT(interest_rate) AS rate_missing

FROM read_parquet('data/processed/hmda_ca_2024_cleaned.parquet')
WHERE action_taken IN (1, 2, 3)
GROUP BY decision_outcome;


SELECT
    loan_type_label,
    COUNT(*) AS applications,
    ROUND(AVG(interest_rate), 3) AS avg_rate,
    ROUND(MEDIAN(interest_rate), 3) AS median_rate
FROM read_parquet('data/processed/hmda_ca_2024_cleaned.parquet')
WHERE action_taken IN (1, 2)
  AND interest_rate IS NOT NULL
GROUP BY loan_type_label
ORDER BY median_rate;


-- ============================================================
-- Rate Spread Analysis
-- ============================================================
SELECT
    COUNT(*) AS total_rows,
    COUNT(rate_spread) AS spread_available,
    COUNT(*) - COUNT(rate_spread) AS spread_missing,
    MIN(rate_spread) AS min_spread,
    MAX(rate_spread) AS max_spread
FROM read_parquet('data/processed/hmda_ca_2024_cleaned.parquet')
WHERE action_taken IN (1, 2, 3);


SELECT
    ROUND(MEDIAN(rate_spread), 3) AS median_spread,
    ROUND(QUANTILE_CONT(rate_spread, 0.25), 3) AS p25_spread,
    ROUND(QUANTILE_CONT(rate_spread, 0.75), 3) AS p75_spread,
    ROUND(QUANTILE_CONT(rate_spread, 0.95), 3) AS p95_spread,
    ROUND(QUANTILE_CONT(rate_spread, 0.99), 3) AS p99_spread
FROM read_parquet('data/processed/hmda_ca_2024_cleaned.parquet')
WHERE action_taken IN (1, 2, 3)
  AND rate_spread IS NOT NULL;


SELECT
    CASE
        WHEN action_taken IN (1, 2) THEN 'Approved'
        WHEN action_taken = 3 THEN 'Denied'
    END AS decision_outcome,

    COUNT(*) AS applications,
    COUNT(rate_spread) AS spread_available,
    COUNT(*) - COUNT(rate_spread) AS spread_missing

FROM read_parquet('data/processed/hmda_ca_2024_cleaned.parquet')
WHERE action_taken IN (1, 2, 3)
GROUP BY decision_outcome;


SELECT
    loan_type_label,
    COUNT(*) AS applications,
    ROUND(AVG(rate_spread), 3) AS avg_spread,
    ROUND(MEDIAN(rate_spread), 3) AS median_spread
FROM read_parquet('data/processed/hmda_ca_2024_cleaned.parquet')
WHERE action_taken IN (1, 2)
  AND rate_spread IS NOT NULL
GROUP BY loan_type_label
ORDER BY median_spread;


-- ============================================================
-- County / Geographic Analysis
-- ============================================================

SELECT
    COUNT(*) AS decisioned_applications,
    COUNT(county_code) AS county_available,
    COUNT(*) - COUNT(county_code) AS county_missing
FROM read_parquet('data/processed/hmda_ca_2024_cleaned.parquet')
WHERE action_taken IN (1, 2, 3);


SELECT
    county_code,
    COUNT(*) AS applications,
    SUM(CASE WHEN action_taken IN (1, 2) THEN 1 ELSE 0 END) AS approved,
    SUM(CASE WHEN action_taken = 3 THEN 1 ELSE 0 END) AS denied,
    ROUND(
        100.0 * SUM(CASE WHEN action_taken IN (1, 2) THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS approval_rate_pct
FROM read_parquet('data/processed/hmda_ca_2024_cleaned.parquet')
WHERE action_taken IN (1, 2, 3)
  AND county_code IS NOT NULL
GROUP BY county_code
HAVING COUNT(*) >= 1000
ORDER BY approval_rate_pct DESC;


-- ============================================================
-- QA Checks
-- ============================================================

WITH county_summary AS (
    SELECT
        county_code,
        COUNT(*) AS applications,
        SUM(CASE WHEN action_taken IN (1, 2) THEN 1 ELSE 0 END) AS approved,
        SUM(CASE WHEN action_taken = 3 THEN 1 ELSE 0 END) AS denied
    FROM read_parquet('data/processed/hmda_ca_2024_cleaned.parquet')
    WHERE action_taken IN (1, 2, 3)
      AND county_code IS NOT NULL
    GROUP BY county_code
    HAVING COUNT(*) >= 1000
)

SELECT *
FROM county_summary
WHERE applications <> approved + denied;