-- ============================================================
-- 01_setup_and_validation.sql
-- California HMDA 2024
-- Setup and validation checks
-- ============================================================

SELECT COUNT(*) AS total_rows
FROM read_parquet('data/processed/hmda_ca_2024_cleaned.parquet');

-- Validate the decisioned application sample

SELECT COUNT(*) AS decisioned_rows
FROM read_parquet('data/processed/hmda_ca_2024_cleaned.parquet')
WHERE action_taken IN (1, 2, 3);

-- Classify decisioned applications as approved or denied

SELECT
    action_taken,
    CASE
        WHEN action_taken IN (1, 2) THEN 'Approved'
        WHEN action_taken = 3 THEN 'Denied'
    END AS decision_outcome,
    COUNT(*) AS applications
FROM read_parquet('data/processed/hmda_ca_2024_cleaned.parquet')
WHERE action_taken IN (1, 2, 3)
GROUP BY action_taken, decision_outcome
ORDER BY action_taken;

-- Calculate overall approval and denial rates

SELECT
    COUNT(*) AS decisioned_applications,
    SUM(CASE WHEN action_taken IN (1, 2) THEN 1 ELSE 0 END) AS approved,
    SUM(CASE WHEN action_taken = 3 THEN 1 ELSE 0 END) AS denied,
    ROUND(
        100.0 * SUM(CASE WHEN action_taken IN (1, 2) THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS approval_rate_pct,
    ROUND(
    100.0 * SUM(CASE WHEN action_taken = 3 THEN 1 ELSE 0 END)
    / COUNT(*),
    2
) AS denial_rate_pct
FROM read_parquet('data/processed/hmda_ca_2024_cleaned.parquet')
WHERE action_taken IN (1, 2, 3);

