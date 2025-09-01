-- This query calculates key marketing KPIs (CAC and ROAS) and compares their performance
-- over two consecutive 30-day periods to identify trends.

-- 1. Calculate base metrics for each individual row to be used in later aggregations.
WITH base_metrics AS (
  SELECT
    *,
    -- Calculate Customer Acquisition Cost (CAC). Use NULLIF to prevent division-by-zero errors.
    spend / NULLIF(conversions, 0) AS cac,
    -- Calculate Return on Ad Spend (ROAS), assuming a fixed revenue of $100 per conversion.
    (conversions * 100) / NULLIF(spend, 0) AS roas
  FROM
    `bionic-genre-470500-t4.ad_spend_data.raw_ad_spend`
),

-- 2. Aggregate metrics for the most recent 30-day period in the dataset.
current_period AS (
  SELECT
    'Last 30 Days' AS period,
    AVG(cac) AS avg_cac,
    AVG(roas) AS avg_roas
  FROM
    base_metrics
  WHERE
    -- Dynamically find the last 30 days based on the latest date in the data.
    date BETWEEN DATE_SUB((SELECT MAX(date) FROM base_metrics), INTERVAL 29 DAY) AND (SELECT MAX(date) FROM base_metrics)
),

-- 3. Aggregate metrics for the 30-day period prior to the current one.
prior_period AS (
  SELECT
    'Prior 30 Days' AS period,
    AVG(cac) AS avg_cac,
    AVG(roas) AS avg_roas
  FROM
    base_metrics
  WHERE
    -- Dynamically find the previous 30-day window.
    date BETWEEN DATE_SUB((SELECT MAX(date) FROM base_metrics), INTERVAL 59 DAY) AND DATE_SUB((SELECT MAX(date) FROM base_metrics), INTERVAL 30 DAY)
),

-- 4. Join the two periods into a single row for easy comparison.
final_comparison AS (
  SELECT
    cp.avg_cac AS current_cac,
    pp.avg_cac AS prior_cac,
    cp.avg_roas AS current_roas,
    pp.avg_roas AS prior_roas
  FROM
    current_period cp, prior_period pp
)

-- 5. Format the final output table, calculating the percentage change (delta) for each KPI.
-- The UNION ALL stacks the results for CAC and ROAS into a final, clean table.
SELECT
  'CAC' AS metric,
  ROUND(current_cac, 2) AS last_30_days,
  ROUND(prior_cac, 2) AS prior_30_days,
  -- Calculate the percentage delta: (new - old) / old
  FORMAT("%.2f%%", ((current_cac - prior_cac) / prior_cac) * 100) AS delta
FROM
  final_comparison
UNION ALL
SELECT
  'ROAS' AS metric,
  ROUND(current_roas, 2) AS last_30_days,
  ROUND(prior_roas, 2) AS prior_30_days,
  FORMAT("%.2f%%", ((current_roas - prior_roas) / prior_roas) * 100) AS delta
FROM
  final_comparison;