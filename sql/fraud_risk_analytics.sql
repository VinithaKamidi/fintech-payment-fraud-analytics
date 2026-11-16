-- FinTech Digital Payments Fraud & Risk Analytics SQL Queries

-- 1. Merchant Category Fraud Rate & Financial Exposure
SELECT 
    merchant_category,
    COUNT(transaction_id) AS total_transactions,
    ROUND(SUM(amount_inr), 2) AS total_gmv_inr,
    SUM(is_fraud) AS confirmed_fraud_txns,
    ROUND(SUM(CASE WHEN is_fraud = 1 THEN amount_inr ELSE 0 END), 2) AS gross_fraud_loss_inr,
    ROUND(CAST(SUM(is_fraud) AS FLOAT) / COUNT(transaction_id) * 100, 2) AS fraud_rate_pct
FROM upi_card_transactions
GROUP BY merchant_category
ORDER BY fraud_rate_pct DESC;

-- 2. Window Function: Detecting Rapid User Velocity & Amount Spikes
WITH user_txn_sequence AS (
    SELECT 
        transaction_id,
        user_id,
        transaction_timestamp,
        amount_inr,
        is_new_device,
        is_fraud,
        LAG(amount_inr) OVER (PARTITION BY user_id ORDER BY transaction_timestamp) AS prev_txn_amount,
        COUNT(transaction_id) OVER (
            PARTITION BY user_id 
            ORDER BY transaction_timestamp 
            ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
        ) AS rolling_4_txn_window
    FROM upi_card_transactions
)
SELECT 
    is_new_device,
    CASE 
        WHEN amount_inr > COALESCE(prev_txn_amount, amount_inr) * 2.5 THEN 'Sudden Amount Spike (>2.5x)'
        ELSE 'Normal Spend Pattern'
    END AS spend_behavior,
    COUNT(*) AS txn_volume,
    ROUND(AVG(CAST(is_fraud AS FLOAT)) * 100, 2) AS fraud_rate_pct
FROM user_txn_sequence
GROUP BY 1, 2
ORDER BY fraud_rate_pct DESC;

-- 3. Risk Engine Threshold Simulation (Score >= 70 Cutoff Evaluation)
SELECT 
    CASE WHEN risk_score >= 70 THEN 'Blocked / Step-Up Auth (Score >= 70)' ELSE 'Auto-Approved (< 70)' END AS rule_decision,
    COUNT(*) AS total_txns,
    SUM(CASE WHEN is_fraud = 1 THEN 1 ELSE 0 END) AS actual_fraud_txns,
    SUM(CASE WHEN is_fraud = 0 THEN 1 ELSE 0 END) AS legitimate_txns,
    ROUND(SUM(amount_inr), 2) AS total_gmv_inr
FROM upi_card_transactions
GROUP BY 1;
