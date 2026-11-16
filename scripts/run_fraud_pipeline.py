import os
import pandas as pd
import numpy as np

def run_fraud_pipeline():
    print("Loading digital payments transaction dataset...")
    df = pd.read_csv("data/upi_card_transactions.csv")
    os.makedirs("outputs", exist_ok=True)

    # 1. Merchant Category Risk Summary
    cat_summary = df.groupby("merchant_category").agg(
        total_txns=("transaction_id", "count"),
        total_gmv_inr=("amount_inr", "sum"),
        fraud_txns=("is_fraud", "sum"),
        fraud_loss_inr=("amount_inr", lambda s: s[df.loc[s.index, "is_fraud"] == 1].sum()),
        avg_risk_score=("risk_score", "mean")
    ).reset_index()
    cat_summary["fraud_rate_pct"] = round((cat_summary["fraud_txns"] / cat_summary["total_txns"]) * 100, 2)
    cat_summary.to_csv("outputs/merchant_fraud_summary.csv", index=False)

    # 2. Threshold Simulation (Precision vs Recall vs False Positive Friction)
    thresholds = [50, 55, 60, 65, 70, 75, 80, 85]
    sim_rows = []
    total_fraud_cases = df["is_fraud"].sum()
    total_legit_cases = (df["is_fraud"] == 0).sum()

    for th in thresholds:
        blocked = df["risk_score"] >= th
        tp = ((blocked) & (df["is_fraud"] == 1)).sum()
        fp = ((blocked) & (df["is_fraud"] == 0)).sum()
        fraud_prevented_inr = df.loc[(blocked) & (df["is_fraud"] == 1), "amount_inr"].sum()
        legit_blocked_inr = df.loc[(blocked) & (df["is_fraud"] == 0), "amount_inr"].sum()

        sim_rows.append({
            "risk_score_threshold": th,
            "fraud_caught_recall_pct": round((tp / total_fraud_cases) * 100, 2),
            "false_positive_rate_pct": round((fp / total_legit_cases) * 100, 2),
            "alert_precision_pct": round((tp / (tp + fp)) * 100, 2) if (tp + fp) > 0 else 0,
            "fraud_loss_prevented_inr": round(fraud_prevented_inr, 2),
            "legit_gmv_blocked_inr": round(legit_blocked_inr, 2)
        })

    pd.DataFrame(sim_rows).to_csv("outputs/rule_threshold_simulation.csv", index=False)
    print("Fraud risk pipeline executed successfully! Outputs saved to outputs/")

if __name__ == "__main__":
    run_fraud_pipeline()
