
# Google Pay – Digital Payments Analytics

## 1. Database Overview

The database is designed to manage and analyze Google Pay digital payment transactions. It stores information about users, transactions, merchants, bank accounts, VPA details, bill payments, rewards, disputes, and cities.

## 2. Database Tables

The database consists of the following tables:

1. users – Stores user information.
2. transactions – Stores digital payment transaction details.
3. merchants – Stores merchant information.
4. bank_accounts – Stores users' bank account details.
5. vpas – Stores Virtual Payment Address details.
6. bill_payments – Stores bill payment information.
7. rewards – Stores cashback and reward details.
8. disputes – Stores transaction dispute information.
9. cities – Stores city-related information.

## 3. Primary Keys

Each table contains a primary key that uniquely identifies every record.

- users: user_id
- transactions: txn_id
- merchants: merchant_id
- bank_accounts: account_id
- vpas: vpa_id
- bill_payments: bill_id
- rewards: reward_id
- disputes: dispute_id
- cities: city_id

## 4. Foreign Key Relationships

The database uses foreign keys to maintain relationships between tables.

- transactions are connected to users.
- transactions are connected to merchants.
- bank_accounts are connected to users.
- vpas are connected to users.
- bill_payments are connected to users.
- rewards are connected to users.
- disputes are connected to transactions.
- users are connected to cities.

## 5. Data Types

The database uses appropriate PostgreSQL data types:

- INTEGER and BIGINT for identifiers.
- VARCHAR for names and text fields.
- NUMERIC for transaction amounts.
- DATE for dates.
- TIMESTAMPTZ for timestamps.
- BOOLEAN for true/false values.

## 6. Database Design Goals

- Maintain data consistency.
- Reduce data redundancy.
- Establish relationships using primary and foreign keys.
- Support efficient SQL queries and data analysis.
- Enable transaction and payment performance analysis.
