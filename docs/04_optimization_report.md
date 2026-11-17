# CP3: Query Optimization Report

## 1. Objective

This report compares the baseline workload performance with the optimized workload performance after creating indexes and rewriting selected SQL queries.

## 2. Methodology

- Database: PostgreSQL (`google_pay_db`)
- Schema: `qpay`
- Workload: 30 queries (R01-R25 and W01-W05)
- Runs per query: 3
- Measurement: average execution time in milliseconds
- Execution plans collected using `EXPLAIN (ANALYZE, BUFFERS)`.
- Write queries were executed inside transactions and rolled back.

## 3. Performance Comparison

| Query | Type | Baseline (ms) | Optimized (ms) | Change | Result |
|---|---|---:|---:|---:|---|
| R01 | READ | 19.825 | 38.022 | -91.8% | Regressed |
| R02 | READ | 0.037 | 0.037 | +0.0% | Similar |
| R03 | READ | 12.155 | 0.102 | +99.2% | Improved |
| R04 | READ | 7.289 | 0.096 | +98.7% | Improved |
| R05 | READ | 7.007 | 0.351 | +95.0% | Improved |
| R06 | READ | 6.686 | 0.478 | +92.9% | Improved |
| R07 | READ | 7.262 | 1.070 | +85.3% | Improved |
| R08 | READ | 121.912 | 121.092 | +0.7% | Similar |
| R09 | READ | 279.487 | 305.579 | -9.3% | Regressed |
| R10 | READ | 1.623 | 0.097 | +94.0% | Improved |
| R11 | READ | 1.783 | 0.107 | +94.0% | Improved |
| R12 | READ | 1.177 | 0.143 | +87.9% | Improved |
| R13 | READ | 22.605 | 22.244 | +1.6% | Improved |
| R14 | READ | 17.168 | 0.102 | +99.4% | Improved |
| R15 | READ | 9.017 | 3.751 | +58.4% | Improved |
| R16 | READ | 0.294 | 0.237 | +19.4% | Improved |
| R17 | READ | 11.308 | 11.408 | -0.9% | Similar |
| R18 | READ | 22.873 | 30.212 | -32.1% | Regressed |
| R19 | READ | 4260.938 | 13.812 | +99.7% | Improved |
| R20 | READ | 9.950 | 9.576 | +3.8% | Improved |
| R21 | READ | 1.066 | 0.993 | +6.8% | Improved |
| R22 | READ | 3.838 | 2.608 | +32.0% | Improved |
| R23 | READ | 59.393 | 18.612 | +68.7% | Improved |
| R24 | READ | 5.047 | 0.165 | +96.7% | Improved |
| R25 | READ | 20.078 | 13.718 | +31.7% | Improved |
| W01 | WRITE | 0.352 | 0.851 | -141.8% | Regressed |
| W02 | WRITE | 19.862 | 0.583 | +97.1% | Improved |
| W03 | WRITE | 1.533 | 0.202 | +86.8% | Improved |
| W04 | WRITE | 1.851 | 1.295 | +30.0% | Improved |
| W05 | WRITE | 2.200 | 3.638 | -65.4% | Regressed |

## 4. Overall Results

- Queries improved by more than 1%: **22**
- Queries regressed by more than 1%: **5**
- Queries with similar performance: **3**

Positive change means execution time decreased. Negative change means execution time increased.

## 5. Major Improvements

- **R19 (READ)**: 4260.938 ms to 13.812 ms (+99.7%).
- **R14 (READ)**: 17.168 ms to 0.102 ms (+99.4%).
- **R03 (READ)**: 12.155 ms to 0.102 ms (+99.2%).
- **R04 (READ)**: 7.289 ms to 0.096 ms (+98.7%).
- **W02 (WRITE)**: 19.862 ms to 0.583 ms (+97.1%).
- **R24 (READ)**: 5.047 ms to 0.165 ms (+96.7%).
- **R05 (READ)**: 7.007 ms to 0.351 ms (+95.0%).
- **R10 (READ)**: 1.623 ms to 0.097 ms (+94.0%).

## 6. Performance Regressions and Observations

- **W01 (WRITE)**: 0.352 ms to 0.851 ms (-141.8%).
- **R01 (READ)**: 19.825 ms to 38.022 ms (-91.8%).
- **W05 (WRITE)**: 2.200 ms to 3.638 ms (-65.4%).
- **R18 (READ)**: 22.873 ms to 30.212 ms (-32.1%).
- **R09 (READ)**: 279.487 ms to 305.579 ms (-9.3%).

Some queries became slower despite indexing. Indexes are not automatically beneficial for every workload: query selectivity, table size, sorting, joins, and planner choices affect execution time.

## 7. Index Usage

The optimized execution plans show usage of indexes including:
- `idx_transactions_initiated_desc`
- `idx_transactions_pending_time`
- `idx_transactions_merchant_time`
- `idx_transactions_success_pair_time`
- `idx_transactions_upi_ref`
- `idx_vpas_user`
- `idx_rewards_user_status_expiry`
- `idx_rewards_unscratched_expiry`
- `idx_bill_payments_user_status_due`
- `idx_disputes_status_raised`
- `idx_merchants_verified_city`

The plans also show that some queries continue to use sequential scans. This can be reasonable when a large proportion of a table must be read.

## 8. Conclusion

The optimized workload demonstrates substantial improvements for several queries, particularly those that can use selective indexes. However, some queries experienced regressions or little change. Further tuning should focus on those queries using their execution plans rather than adding indexes indiscriminately.

## 9. Reproducibility

Baseline results: `benchmarks/results/baseline/summary.csv`

Optimized results: `benchmarks/results/after/summary.csv`

Optimized raw execution plans: `benchmarks/results/after/`

Index definitions: `sql/05_indexes.sql`

Optimized workload: `sql/06_optimized_queries.sql`
