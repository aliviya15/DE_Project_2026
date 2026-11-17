SET search_path TO qpay;

-- 1. Check NULL values in users
SELECT
    COUNT(*) AS total_users,
    COUNT(*) FILTER (WHERE full_name IS NULL) AS null_names,
    COUNT(*) FILTER (WHERE phone_number IS NULL) AS null_phones,
    COUNT(*) FILTER (WHERE city_id IS NULL) AS null_city
FROM users;

-- 2. Check duplicate phone numbers
SELECT phone_number, COUNT(*)
FROM users
GROUP BY phone_number
HAVING COUNT(*) > 1;

-- 3. Check duplicate VPAs
SELECT vpa, COUNT(*)
FROM vpas
GROUP BY vpa
HAVING COUNT(*) > 1;

-- 4. Check transaction status
SELECT status, COUNT(*)
FROM transactions
GROUP BY status
ORDER BY COUNT(*) DESC;