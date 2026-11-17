-- CP3: Indexes for Google Pay Digital Payments workload
SET search_path TO qpay;

-- Transaction history: sent and received payments
CREATE INDEX IF NOT EXISTS idx_transactions_payer_time
ON transactions (payer_vpa, initiated_at DESC);

CREATE INDEX IF NOT EXISTS idx_transactions_payee_time
ON transactions (payee_vpa, initiated_at DESC);

-- Pending payment reconciliation and bank callbacks
CREATE INDEX IF NOT EXISTS idx_transactions_pending_time
ON transactions (initiated_at)
WHERE status = 'PENDING';

-- Merchant collections and merchant payment reports
CREATE INDEX IF NOT EXISTS idx_transactions_merchant_time
ON transactions (merchant_id, initiated_at);

CREATE INDEX IF NOT EXISTS idx_transactions_merchant_success
ON transactions (merchant_id)
WHERE status = 'SUCCESS';

-- Fraud detection and transaction reporting
CREATE INDEX IF NOT EXISTS idx_transactions_type_status_time
ON transactions (txn_type, status, initiated_at);

-- Newest-first transaction listing
CREATE INDEX IF NOT EXISTS idx_transactions_initiated_desc
ON transactions (initiated_at DESC);

-- UPI reference lookup
CREATE INDEX IF NOT EXISTS idx_transactions_upi_ref
ON transactions (upi_ref);

-- User's VPA and bank account lookup
CREATE INDEX IF NOT EXISTS idx_vpas_user
ON vpas (user_id);

CREATE INDEX IF NOT EXISTS idx_bank_accounts_user
ON bank_accounts (user_id);

-- Rewards lookup and expiry notifications
CREATE INDEX IF NOT EXISTS idx_rewards_user_status_expiry
ON rewards (user_id, status, expires_at);

CREATE INDEX IF NOT EXISTS idx_rewards_unscratched_expiry
ON rewards (expires_at)
WHERE status = 'UNSCRATCHED';

-- Bill reminders
CREATE INDEX IF NOT EXISTS idx_bill_payments_user_status_due
ON bill_payments (user_id, status, due_date);

-- Open dispute SLA checks
CREATE INDEX IF NOT EXISTS idx_disputes_status_raised
ON disputes (status, raised_at);

-- Verified merchant lookup by city
CREATE INDEX IF NOT EXISTS idx_merchants_verified_city
ON merchants (city_id)
WHERE is_verified = TRUE;


-- Optimized R09: Previous successful payment lookup
CREATE INDEX IF NOT EXISTS idx_transactions_success_pair_time
ON transactions (payer_vpa, payee_vpa, initiated_at DESC)
WHERE status = 'SUCCESS';
