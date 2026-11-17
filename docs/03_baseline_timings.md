# Phase 3: Baseline Query Benchmark

## Benchmark setup

- Database: `google_pay_db`
- Schema: `qpay`
- Workload: `queries/workload_30.sql`
- Queries: 25 read queries (R01-R25) and 5 write queries (W01-W05)
- Measurement: `EXPLAIN (ANALYZE, BUFFERS)`; 3 runs per query
- Write queries were benchmarked safely using transaction rollback.
- Raw execution plans are stored in `benchmarks/results/baseline/`.

## Execution timings

| Query | Purpose | Type | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Average (ms) |
|---|---|---|---:|---:|---:|---:|
| R01 | Transaction history: everything user 15177 sent or received, newest first | READ | 26.554 | 17.396 | 15.526 | 19.825 |
| R02 | "Pay to UPI ID": check that the entered VPA exists and is active | READ | 0.040 | 0.035 | 0.036 | 0.037 |
| R03 | UPI limit check: total successfully sent by user 15177 on 30 June 2026 (limit ₹1,00,000/day) | READ | 11.651 | 12.400 | 12.415 | 12.155 |
| R04 | Reconciliation: payments still PENDING more than 15 minutes after 23:59 on 30 Jun 2026 | READ | 7.227 | 7.646 | 6.994 | 7.289 |
| R05 | Google Pay for Business: hourly collections of merchant 2 on 29 June 2026 | READ | 6.895 | 7.147 | 6.980 | 7.007 |
| R06 | Settlement: amount to settle to every merchant for 29 June 2026 | READ | 6.623 | 6.797 | 6.639 | 6.686 |
| R07 | Bank health: failure codes per payer bank in the last 7 days | READ | 7.376 | 7.173 | 7.236 | 7.262 |
| R08 | Fraud: VPAs that received P2P money from 5+ different people on the same day | READ | 122.457 | 120.483 | 122.797 | 121.912 |
| R09 | Fraud: repeated payments—same payer to the same payee within 10 minutes of the previous one | READ | 265.149 | 308.958 | 264.353 | 279.487 |
| R10 | Rewards tab: user 15177's unscratched cards that have not expired | READ | 1.654 | 1.636 | 1.580 | 1.623 |
| R11 | Notification job: unscratched rewards that expire in the first 3 days of July | READ | 1.826 | 1.868 | 1.656 | 1.783 |
| R12 | Bill reminders: user 1072's unpaid bills due in the next 7 days | READ | 1.178 | 1.165 | 1.188 | 1.177 |
| R13 | Merchant success team: merchants who have never received a payment (to call and help them) | READ | 22.553 | 23.395 | 21.868 | 22.605 |
| R14 | Spend analysis: user 15177's 2026 spending per merchant category code (MCC) | READ | 17.061 | 17.231 | 17.213 | 17.168 |
| R15 | Business insights: top 10 merchants by June 2026 GMV in each city | READ | 9.195 | 9.069 | 8.788 | 9.017 |
| R16 | Disputes desk: disputes open for more than 7 days (SLA breached) | READ | 0.290 | 0.292 | 0.299 | 0.294 |
| R17 | Merchant risk: refund rate per merchant (at least 30 payments) | READ | 11.646 | 11.143 | 11.135 | 11.308 |
| R18 | Compliance: users without verified KYC who have successfully sent ₹10,000+ in total | READ | 22.825 | 22.935 | 22.859 | 22.873 |
| R19 | Merchant report: last payment time and successful payment count of every verified Bengaluru merchant | READ | 4157.200 | 4255.195 | 4370.419 | 4260.938 |
| R20 | Platform health: daily success rate in June 2026 | READ | 10.135 | 9.968 | 9.746 | 9.950 |
| R21 | "Search businesses": merchants with "chai" in their name | READ | 1.118 | 1.028 | 1.052 | 1.066 |
| R22 | Payment screen: user 15177's primary bank account and all their UPI IDs | READ | 3.873 | 3.791 | 3.850 | 3.838 |
| R23 | Operations console: all transactions, newest first, page 8,001 (25 per page) | READ | 59.190 | 58.750 | 60.238 | 59.393 |
| R24 | Customer support: find a payment by its UPI reference number | READ | 5.159 | 5.049 | 4.932 | 5.047 |
| R25 | Bank health: average seconds from initiation to completion per payer bank (June 2026) | READ | 20.714 | 20.144 | 19.376 | 20.078 |
| W01 | Pay: user 15177 starts a ₹250 payment to merchant 2 (PENDING until the bank confirms) | WRITE | 0.373 | 0.343 | 0.341 | 0.352 |
| W02 | Bank callback: mark the oldest PENDING payment as successful | WRITE | 20.408 | 19.568 | 19.610 | 19.862 |
| W03 | Scratch card: user 15177 scratches their oldest unscratched card | WRITE | 1.696 | 1.504 | 1.399 | 1.533 |
| W04 | Nightly job (run at 00:00 on 4 Jul 2026): expire every reward whose time is up | WRITE | 2.025 | 1.735 | 1.792 | 1.851 |
| W05 | Nightly job: bills past their due date and still unpaid become OVERDUE | WRITE | 2.818 | 1.914 | 1.869 | 2.200 |

## Observed scan types and interpretation

The scan nodes below are taken from the benchmark summary. Sequential scans read table rows to evaluate the query; they can be expected when a query needs to examine a large part of a table or does not have a suitable selective index. Index scans use an index to locate matching rows, which is useful for selective lookups. The best scan depends on table size, filter selectivity, and query structure.

| Query | Observed scan nodes | Interpretation |
|---|---|---|
| R01 | Seq Scan on transactions | Seq Scan on vpas | Sequential scan observed; the query may need to examine many rows or lacks a sufficiently selective usable index. |
| R02 | Index Scan using vpas_pkey on vpas | Index Scan using users_pkey on users | Index scan observed; an index is used to locate matching rows. |
| R03 | Seq Scan on transactions | Seq Scan on vpas | Sequential scan observed; the query may need to examine many rows or lacks a sufficiently selective usable index. |
| R04 | Seq Scan on transactions | Sequential scan observed; the query may need to examine many rows or lacks a sufficiently selective usable index. |
| R05 | Seq Scan on transactions | Sequential scan observed; the query may need to examine many rows or lacks a sufficiently selective usable index. |
| R06 | Seq Scan on transactions | Index Scan using merchants_pkey on merchants | Uses both sequential and index scans; broad filtering or aggregation may require scanning rows, while joins/lookups use indexes. |
| R07 | Seq Scan on transactions | Index Scan using vpas_pkey on vpas | Index Scan using bank_accounts_pkey on bank_accounts | Uses both sequential and index scans; broad filtering or aggregation may require scanning rows, while joins/lookups use indexes. |
| R08 | Seq Scan on transactions | Sequential scan observed; the query may need to examine many rows or lacks a sufficiently selective usable index. |
| R09 | Seq Scan on transactions | Sequential scan observed; the query may need to examine many rows or lacks a sufficiently selective usable index. |
| R10 | Seq Scan on rewards | Sequential scan observed; the query may need to examine many rows or lacks a sufficiently selective usable index. |
| R11 | Seq Scan on rewards | Sequential scan observed; the query may need to examine many rows or lacks a sufficiently selective usable index. |
| R12 | Seq Scan on bill_payments | Sequential scan observed; the query may need to examine many rows or lacks a sufficiently selective usable index. |
| R13 | Seq Scan on merchants | Seq Scan on transactions | Sequential scan observed; the query may need to examine many rows or lacks a sufficiently selective usable index. |
| R14 | Seq Scan on transactions | Seq Scan on vpas | Index Scan using merchants_pkey on merchants | Uses both sequential and index scans; broad filtering or aggregation may require scanning rows, while joins/lookups use indexes. |
| R15 | Seq Scan on transactions | Seq Scan on merchants | Sequential scan observed; the query may need to examine many rows or lacks a sufficiently selective usable index. |
| R16 | Seq Scan on disputes | Index Scan using transactions_pkey on transactions | Uses both sequential and index scans; broad filtering or aggregation may require scanning rows, while joins/lookups use indexes. |
| R17 | Seq Scan on transactions | Sequential scan observed; the query may need to examine many rows or lacks a sufficiently selective usable index. |
| R18 | Seq Scan on transactions | Seq Scan on vpas | Seq Scan on users | Sequential scan observed; the query may need to examine many rows or lacks a sufficiently selective usable index. |
| R19 | Seq Scan on merchants | Seq Scan on transactions | Sequential scan observed; the query may need to examine many rows or lacks a sufficiently selective usable index. |
| R20 | Seq Scan on transactions | Sequential scan observed; the query may need to examine many rows or lacks a sufficiently selective usable index. |
| R21 | Seq Scan on merchants | Sequential scan observed; the query may need to examine many rows or lacks a sufficiently selective usable index. |
| R22 | Seq Scan on vpas | Seq Scan on bank_accounts | Sequential scan observed; the query may need to examine many rows or lacks a sufficiently selective usable index. |
| R23 | Seq Scan on transactions | Sequential scan observed; the query may need to examine many rows or lacks a sufficiently selective usable index. |
| R24 | Seq Scan on transactions | Sequential scan observed; the query may need to examine many rows or lacks a sufficiently selective usable index. |
| R25 | Seq Scan on transactions | Seq Scan on vpas | Seq Scan on bank_accounts | Sequential scan observed; the query may need to examine many rows or lacks a sufficiently selective usable index. |
| W01 | (no scan) | No table scan node reported for this write operation. |
| W02 | Index Scan using transactions_pkey on transactions | Index scan observed; an index is used to locate matching rows. |
| W03 | Seq Scan on rewards | Index Scan using rewards_pkey on rewards | Uses both sequential and index scans; broad filtering or aggregation may require scanning rows, while joins/lookups use indexes. |
| W04 | Seq Scan on rewards | Sequential scan observed; the query may need to examine many rows or lacks a sufficiently selective usable index. |
| W05 | Seq Scan on bill_payments | Sequential scan observed; the query may need to examine many rows or lacks a sufficiently selective usable index. |

## Baseline observations

- Slowest query: **R19** (4260.938 ms average) — Merchant report: last payment time and successful payment count of every verified Bengaluru merchant.
- Second slowest query: **R09** (279.487 ms average).
- Third slowest query: **R08** (121.912 ms average).
- The baseline shows several transaction queries using sequential scans.
- These measurements will be used as the before-optimization reference for Phase 4.

## Raw benchmark results

All 30 raw plan files and `summary.csv` are retained in `benchmarks/results/baseline/`.
Each raw plan file contains the three execution-time measurements and the corresponding EXPLAIN output.
