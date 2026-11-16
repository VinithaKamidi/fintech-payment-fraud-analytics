# Power BI Setup & DAX Guide for FinTech Fraud Analytics

## Core DAX Measures
1. **Total Transaction GMV (INR):**
   ```dax
   Total GMV = SUM(upi_card_transactions[amount_inr])
   ```
2. **Confirmed Fraud Rate %:**
   ```dax
   Fraud Rate % = DIVIDE(CALCULATE(COUNT(upi_card_transactions[transaction_id]), upi_card_transactions[is_fraud] = 1), COUNT(upi_card_transactions[transaction_id]), 0)
   ```
3. **Gross Fraud Loss (INR):**
   ```dax
   Gross Fraud Loss = CALCULATE(SUM(upi_card_transactions[amount_inr]), upi_card_transactions[is_fraud] = 1)
   ```
4. **Fraud Prevented at Cutoff (Score >= 70):**
   ```dax
   Fraud Prevented = CALCULATE(SUM(upi_card_transactions[amount_inr]), upi_card_transactions[is_fraud] = 1, upi_card_transactions[risk_score] >= 70)
   ```
5. **False Positive Rate % (Legitimate Txns Blocked):**
   ```dax
   False Positive Rate % = DIVIDE(CALCULATE(COUNT(upi_card_transactions[transaction_id]), upi_card_transactions[is_fraud] = 0, upi_card_transactions[risk_score] >= 70), CALCULATE(COUNT(upi_card_transactions[transaction_id]), upi_card_transactions[is_fraud] = 0), 0)
   ```
