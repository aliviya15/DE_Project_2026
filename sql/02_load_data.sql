SELECT 'cities' AS table_name, COUNT(*) FROM qpay.cities
UNION ALL
SELECT 'users', COUNT(*) FROM qpay.users
UNION ALL
SELECT 'bank_accounts', COUNT(*) FROM qpay.bank_accounts
UNION ALL
SELECT 'merchants', COUNT(*) FROM qpay.merchants
UNION ALL
SELECT 'vpas', COUNT(*) FROM qpay.vpas
UNION ALL
SELECT 'transactions', COUNT(*) FROM qpay.transactions
UNION ALL
SELECT 'bill_payments', COUNT(*) FROM qpay.bill_payments
UNION ALL
SELECT 'disputes', COUNT(*) FROM qpay.disputes
UNION ALL
SELECT 'rewards', COUNT(*) FROM qpay.rewards;