-- ==================================================
-- California HMDA Mortgage Lending Analysis
-- 02. Approval Analysis
-- ==================================================


-- ============================================================
-- Approval by Loan Purpose
-- ============================================================
SELECT
    loan_purpose_label,
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
GROUP BY loan_purpose_label
ORDER BY approval_rate_pct DESC;


-- ============================================================
-- Approval by Loan Type
-- ============================================================
SELECT
    loan_type_label,
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
GROUP BY loan_type_label
ORDER BY approval_rate_pct DESC;


-- ============================================================
-- Loan Purpose Ranking and Window Functions
-- ============================================================
WITH decisioned AS (
    SELECT *
    FROM read_parquet('data/processed/hmda_ca_2024_cleaned.parquet')
    WHERE action_taken IN (1, 2, 3)
),

loan_purpose_summary AS (
    SELECT
        loan_purpose_label,
        COUNT(*) AS applications,
        SUM(CASE WHEN action_taken IN (1, 2) THEN 1 ELSE 0 END) AS approved,
        SUM(CASE WHEN action_taken = 3 THEN 1 ELSE 0 END) AS denied,
        ROUND(
            100.0 * SUM(CASE WHEN action_taken IN (1, 2) THEN 1 ELSE 0 END)
            / COUNT(*),
            2
        ) AS approval_rate_pct
    FROM decisioned
    GROUP BY loan_purpose_label
    HAVING COUNT(*) >= 1000
)

SELECT
    loan_purpose_label,
    applications,
    approved,
    denied,
    approval_rate_pct,
    RANK() OVER (
        ORDER BY approval_rate_pct DESC
    ) AS approval_rate_rank
FROM loan_purpose_summary;


-- ============================================================
-- Loan Purpose x Loan Type Analysis
-- ============================================================
WITH decisioned AS (
    SELECT *
    FROM read_parquet('data/processed/hmda_ca_2024_cleaned.parquet')
    WHERE action_taken IN (1, 2, 3)
),

loan_purpose_type_summary AS (
    SELECT
        loan_purpose_label,
        loan_type_label,
        COUNT(*) AS applications,
        SUM(CASE WHEN action_taken IN (1, 2) THEN 1 ELSE 0 END) AS approved,
        SUM(CASE WHEN action_taken = 3 THEN 1 ELSE 0 END) AS denied,
        ROUND(
            100.0 * SUM(CASE WHEN action_taken IN (1, 2) THEN 1 ELSE 0 END)
            / COUNT(*),
            2
        ) AS approval_rate_pct
    FROM decisioned
    GROUP BY loan_purpose_label, loan_type_label
    HAVING COUNT(*) >= 1000
)

SELECT *
FROM loan_purpose_type_summary
ORDER BY loan_purpose_label, approval_rate_pct DESC;



WITH decisioned AS (
    SELECT *
    FROM read_parquet('data/processed/hmda_ca_2024_cleaned.parquet')
    WHERE action_taken IN (1, 2, 3)
),

loan_purpose_type_summary AS (
    SELECT
        loan_purpose_label,
        loan_type_label,
        COUNT(*) AS applications,
        SUM(CASE WHEN action_taken IN (1, 2) THEN 1 ELSE 0 END) AS approved,
        SUM(CASE WHEN action_taken = 3 THEN 1 ELSE 0 END) AS denied,
        ROUND(
            100.0 * SUM(CASE WHEN action_taken IN (1, 2) THEN 1 ELSE 0 END)
            / COUNT(*),
            2
        ) AS approval_rate_pct
    FROM decisioned
    GROUP BY loan_purpose_label, loan_type_label
    HAVING COUNT(*) >= 1000
)

SELECT
    loan_purpose_label,
    loan_type_label,
    applications,
    approved,
    denied,
    approval_rate_pct,
    RANK() OVER (
        PARTITION BY loan_purpose_label
        ORDER BY approval_rate_pct DESC
    ) AS approval_rate_rank
FROM loan_purpose_type_summary;



-- ============================================================
-- Denial Reasons
-- ============================================================
SELECT
    denial_reason_1_label,
    COUNT(*) AS denied_applications,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS denial_share_pct
FROM read_parquet('data/processed/hmda_ca_2024_cleaned.parquet')
WHERE action_taken = 3
GROUP BY denial_reason_1_label
ORDER BY denied_applications DESC;


SELECT
    loan_type_label,
    denial_reason_1_label,
    COUNT(*) AS denied_applications
FROM read_parquet('data/processed/hmda_ca_2024_cleaned.parquet')
WHERE action_taken = 3
GROUP BY loan_type_label, denial_reason_1_label
ORDER BY loan_type_label, denied_applications DESC;


SELECT
    loan_type_label,
    denial_reason_1_label,
    COUNT(*) AS denied_applications,
    ROUND(
    100.0 * COUNT(*)
    / SUM(COUNT(*)) OVER (
        PARTITION BY loan_type_label
    ),
    2
) AS reason_share_within_loan_type_pct
FROM read_parquet('data/processed/hmda_ca_2024_cleaned.parquet')
WHERE action_taken = 3
GROUP BY loan_type_label, denial_reason_1_label
ORDER BY loan_type_label, denied_applications DESC;
