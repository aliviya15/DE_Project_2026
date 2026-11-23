# CP4: Scalability and Partitioning Report

## 1. Objective

The objective of this checkpoint is to evaluate query performance on the existing transaction dataset, examine the use of PostgreSQL table partitioning, and understand how partitioning affects different query patterns.

## 2. Dataset and Environment

- Database: PostgreSQL (`google_pay_db`)
- Schema: `qpay`
- Original transaction table: `qpay.transactions`
- Total transactions: 250,468
- Date range: 2025-01-01 to 2026-06-30
- Partitioning strategy: HASH partitioning on `txn_id`
- Number of partitions: 4
- Benchmark workload: 30 queries (R01-R25 and W01-W05)
- Runs per query: 3
- Measurement: average execution time in milliseconds
- Execution plans: `EXPLAIN (ANALYZE, BUFFERS)`
- Write queries were executed inside transactions and rolled back.

The large benchmark uses the existing 250,468-row dataset. No additional synthetic transactions were generated for this benchmark.

## 3. Full Workload Benchmark

The complete 30-query workload was executed three times. The average execution time and observed scan nodes are recorded in:

`benchmarks/results/large/summary.csv`

### 3.1 Selected Query Observations

| Query | Average Time (ms) | Observed Scan | Observation |
|---|---:|---|---|
| R01 | 40.029 | Index Scan | Uses transaction time and VPA indexes |
| R08 | 120.965 | Seq Scan | Full transaction scan |
| R09 | 163.661 | Index Scan | Uses payer-time index |
| R13 | 24.662 | Seq Scan | Sequential scans on merchants and transactions |
| R19 | 3.679 | Bitmap Heap Scan / Index Only Scan | Uses merchant-related indexes |
| R24 | 0.032 | Index Scan | Efficient UPI reference lookup |
| W05 | 5.177 | Seq Scan | Sequential scan on bill_payments |

### 3.2 Observations

- Selective lookups such as R24 completed quickly using an index.
- R08 and R09 remained relatively expensive, indicating that analytical and window-function workloads can require more optimization.
- Some sequential scans are reasonable when a query needs to process a large portion of a table.
- Indexes improve selected access patterns, but do not guarantee that every query becomes faster.

## 4. Partitioning Design

The original `transactions` table was not replaced. Instead, a separate experimental table named `transactions_partitioned` was created.

The experimental table uses:

`PARTITION BY HASH (txn_id)`

Four partitions were created:

- `transactions_p0`
- `transactions_p1`
- `transactions_p2`
- `transactions_p3`

The original table contains foreign-key dependencies from other tables, including `disputes` and `rewards`. Keeping the original table unchanged avoids breaking those relationships during the experiment.

The partitioned copy contains the same transaction rows as the original table.

### 4.1 Row Distribution

| Table / Partition | Rows |
|---|---:|
| Original transactions | 250,468 |
| Partition p0 | 62,488 |
| Partition p1 | 62,820 |
| Partition p2 | 62,509 |
| Partition p3 | 62,651 |
| Partitioned total | 250,468 |

The rows are distributed across the four hash partitions.

## 5. Original vs Partitioned Query Performance

Three representative query patterns were tested against the original and partitioned tables.

| Query Pattern | Original (ms) | Partitioned (ms) | Observation |
|---|---:|---:|---|
| UPI reference lookup | 0.721 | 1.760 | Partitioned table was slower |
| June 2026 date-range count | 1.975 | 3.209 | Partitioned table was slower |
| Transaction ID lookup | 0.110 | 0.032 | Partitioned table was faster |

These are exploratory single-run measurements, not three-run averages. They should therefore be treated as preliminary observations rather than definitive performance guarantees.

### 5.1 UPI Reference Lookup

The original table used `idx_transactions_upi_ref`.

The partitioned table performed an Append operation and searched the corresponding UPI reference index in all four partitions. Since the partition key is `txn_id`, the UPI reference condition cannot eliminate partitions.

Observed execution time increased from 0.721 ms to 1.760 ms.

### 5.2 Date-Range Query

The original table used `idx_transactions_initiated_desc`.

The partitioned table used indexes across all four partitions. Since partitioning is based on `txn_id`, a date condition on `initiated_at` cannot prune partitions.

Observed execution time increased from 1.975 ms to 3.209 ms.

### 5.3 Transaction ID Lookup

The original table used its primary-key index.

The partitioned table used partition pruning and searched only the relevant partition (`transactions_p1` for the tested transaction ID).

Observed execution time decreased from 0.110 ms to 0.032 ms.

This demonstrates how hash partitioning can help queries that filter directly on the partition key.

## 6. Scalability Analysis

The experiment shows that partitioning is not automatically beneficial for every query.

- HASH partitioning on `txn_id` is useful for transaction ID lookups because PostgreSQL can identify the relevant partition.
- Queries filtering on `upi_ref` or `initiated_at` still need to search across partitions.
- A date-based RANGE partitioning strategy could be more suitable for date-range workloads.
- However, partitioning by date would require careful redesign of the primary key and foreign-key relationships because the existing transaction table is referenced by other tables.

The current hash-partitioned table is therefore an experimental copy for evaluating partition pruning, not a replacement for the production-style original table.

## 7. Limitations

- The full workload benchmark was performed on the existing dataset of 250,468 transactions; it was not a synthetic multi-million-row stress test.
- The three partitioning comparisons were exploratory single-run measurements.
- Results can vary with cache state, system load, and PostgreSQL query planning.
- The experimental partitioned copy does not reproduce the original table's foreign-key relationships.

Further testing with repeated runs and a larger dataset would provide stronger evidence about scalability.

## 8. Conclusion

The full workload benchmark records the performance of all 30 queries over three runs. The partitioning experiment demonstrates that HASH partitioning on `txn_id` improves the tested transaction ID lookup, but makes the tested UPI reference and date-range queries slower because they cannot benefit from partition pruning.

The experiment highlights the importance of selecting a partition key based on actual query patterns. Partitioning should be introduced only after considering query filters, indexes, primary keys, and foreign-key dependencies.

## 9. Reproducibility

- Partitioning SQL: `sql/08_partitioning.sql`
- Full workload: `queries/workload_30.sql`
- Benchmark script: `benchmarks/run_benchmark.sh`
- Full workload results: `benchmarks/results/large/summary.csv`
- Partitioned table: `qpay.transactions_partitioned`
- Original table: `qpay.transactions`
