-- CP4: Experimental HASH partitioning for transaction scalability
-- Original qpay.transactions table and its foreign keys remain untouched.

SET search_path TO qpay;

BEGIN;

CREATE TABLE transactions_partitioned (
    LIKE transactions INCLUDING DEFAULTS INCLUDING CONSTRAINTS
) PARTITION BY HASH (txn_id);

ALTER TABLE transactions_partitioned
ADD PRIMARY KEY (txn_id);

CREATE TABLE transactions_p0
PARTITION OF transactions_partitioned
FOR VALUES WITH (MODULUS 4, REMAINDER 0);

CREATE TABLE transactions_p1
PARTITION OF transactions_partitioned
FOR VALUES WITH (MODULUS 4, REMAINDER 1);

CREATE TABLE transactions_p2
PARTITION OF transactions_partitioned
FOR VALUES WITH (MODULUS 4, REMAINDER 2);

CREATE TABLE transactions_p3
PARTITION OF transactions_partitioned
FOR VALUES WITH (MODULUS 4, REMAINDER 3);

INSERT INTO transactions_partitioned
SELECT * FROM transactions;

CREATE INDEX idx_tp_payer_time
ON transactions_partitioned (payer_vpa, initiated_at DESC);

CREATE INDEX idx_tp_initiated_desc
ON transactions_partitioned (initiated_at DESC);

CREATE INDEX idx_tp_upi_ref
ON transactions_partitioned (upi_ref);

COMMIT;
