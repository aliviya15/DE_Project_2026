
-- Google Pay Digital Payments Database

CREATE SCHEMA IF NOT EXISTS qpay;

SET search_path TO qpay;

-- 1. Cities Table

CREATE TABLE cities (
    city_id INTEGER PRIMARY KEY,
    city_name VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL
);

-- 2. Users Table

CREATE TABLE users (
    user_id INTEGER PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(15) UNIQUE NOT NULL,
    email VARCHAR(150),
    city_id INTEGER REFERENCES cities(city_id),
    kyc_status VARCHAR(20),
    is_blocked BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ
);
-- 3. Bank Accounts Table

CREATE TABLE bank_accounts (
    account_id INTEGER PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id),
    bank_name VARCHAR(100) NOT NULL,
    ifsc VARCHAR(11) NOT NULL,
    account_last4 VARCHAR(4) NOT NULL,
    account_type VARCHAR(20) NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE,
    linked_at TIMESTAMPTZ
);
-- 4. Merchants Table

CREATE TABLE merchants (
    merchant_id INTEGER PRIMARY KEY,
    merchant_name VARCHAR(100) NOT NULL,
    mcc INTEGER,
    merchant_vpa VARCHAR(150) UNIQUE NOT NULL,
    city_id INTEGER REFERENCES cities(city_id),
    is_verified BOOLEAN DEFAULT FALSE,
    onboarded_on DATE
);
-- 5. VPAs Table

CREATE TABLE vpas (
    vpa VARCHAR(150) PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id),
    account_id INTEGER REFERENCES bank_accounts(account_id),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ
);

-- 6. Transactions Table

CREATE TABLE transactions (
    txn_id BIGINT PRIMARY KEY,
    upi_ref VARCHAR(50),
    txn_type VARCHAR(20),
    payer_vpa VARCHAR(150),
    payee_vpa VARCHAR(150),
    merchant_id INTEGER REFERENCES merchants(merchant_id),
    amount NUMERIC(12,2) NOT NULL,
    note TEXT,
    initiated_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    status VARCHAR(20),
    failure_code VARCHAR(50)
);

-- 7. Bill Payments Table
CREATE TABLE bill_payments (
    bill_id BIGINT PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id),
    biller_category VARCHAR(50),
    biller_name VARCHAR(100),
    consumer_number VARCHAR(50),
    amount NUMERIC(12,2) NOT NULL,
    due_date DATE,
    status VARCHAR(20),
    paid_at TIMESTAMPTZ
);

-- 9. Disputes Table
CREATE TABLE disputes (
    dispute_id BIGINT PRIMARY KEY,
    txn_id BIGINT REFERENCES transactions(txn_id),
    raised_by INTEGER,
    reason VARCHAR(100),
    raised_at TIMESTAMPTZ,
    status VARCHAR(20),
    resolved_at TIMESTAMPTZ
);
-- 10. Rewards Table
CREATE TABLE rewards (
    reward_id BIGINT PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id),
    txn_id BIGINT REFERENCES transactions(txn_id),
    reward_type VARCHAR(50),
    amount NUMERIC(12,2),
    status VARCHAR(20),
    issued_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    credited_at TIMESTAMPTZ
);
