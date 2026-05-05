
# Клиенты с непрерывной историей
WITH checks AS (
    SELECT 
        Id_check,
        ID_client,
        date_new,
        SUM(Sum_payment) AS check_amount
    FROM TRANSACTIONS
    GROUP BY Id_check, ID_client, date_new
),
monthly AS (
    SELECT 
        ID_client,
        DATE_FORMAT(date_new, '%Y-%m') AS ym
    FROM checks
    WHERE date_new >= '2015-06-01'
      AND date_new < '2016-06-01'
    GROUP BY ID_client, ym
)
SELECT ID_client
FROM monthly
GROUP BY ID_client
HAVING COUNT(DISTINCT ym) = 12;

# Метрики по этим клиентам
WITH checks AS (
    SELECT 
        Id_check,
        ID_client,
        date_new,
        SUM(Sum_payment) AS check_amount
    FROM TRANSACTIONS
    GROUP BY Id_check, ID_client, date_new
),
good_clients AS (
    SELECT ID_client
    FROM (
        SELECT 
            ID_client,
            DATE_FORMAT(date_new, '%Y-%m') AS ym
        FROM checks
        WHERE date_new >= '2015-06-01'
          AND date_new < '2016-06-01'
        GROUP BY ID_client, ym
    ) t
    GROUP BY ID_client
    HAVING COUNT(DISTINCT ym) = 12
)
SELECT 
    c.ID_client,
    AVG(c.check_amount) AS avg_check,
    SUM(c.check_amount)/12 AS avg_monthly_spend,
    COUNT(*) AS total_transactions
FROM checks c
JOIN good_clients g ON c.ID_client = g.ID_client
WHERE c.date_new >= '2015-06-01'
  AND c.date_new < '2016-06-01'
GROUP BY c.ID_client;


# Метрики по месяцам
WITH checks AS (
    SELECT 
        Id_check,
        ID_client,
        date_new,
        SUM(Sum_payment) AS check_amount
    FROM TRANSACTIONS
    GROUP BY Id_check, ID_client, date_new
)
SELECT 
    DATE_FORMAT(date_new, '%Y-%m') AS month,
    AVG(check_amount) AS avg_check,
    COUNT(*) AS total_transactions,
    COUNT(DISTINCT ID_client) AS unique_customers,
    COUNT(*) / COUNT(DISTINCT ID_client) AS avg_tx_per_customer
FROM checks
WHERE date_new >= '2015-06-01'
  AND date_new < '2016-06-01'
GROUP BY month;


# Доли операций и суммы
WITH checks AS (
    SELECT 
        Id_check,
        ID_client,
        date_new,
        SUM(Sum_payment) AS check_amount
    FROM transactions
    GROUP BY Id_check, ID_client, date_new
),
totals AS (
    SELECT 
        COUNT(*) AS total_tx,
        SUM(check_amount) AS total_amount
    FROM checks
    WHERE date_new >= '2015-06-01'
      AND date_new < '2016-06-01'
)

SELECT 
    DATE_FORMAT(c.date_new, '%Y-%m') AS month,
    
    -- доля операций
    COUNT(*) * 1.0 / t.total_tx AS share_tx,
    
    -- доля суммы
    SUM(c.check_amount) * 1.0 / t.total_amount AS share_amount

FROM checks c
JOIN totals t
WHERE c.date_new >= '2015-06-01'
  AND c.date_new < '2016-06-01'
GROUP BY month, t.total_tx, t.total_amount
ORDER BY month;


# Возрастные группы (шаг 10 лет)
WITH checks AS (
    SELECT 
        Id_check,
        ID_client,
        date_new,
        SUM(Sum_payment) AS check_amount
    FROM transactions
    GROUP BY Id_check, ID_client, date_new
),
age_groups AS (
    SELECT 
        Id_client,
        CASE 
            WHEN Age IS NULL THEN 'NA'
            ELSE CONCAT(FLOOR(Age/10)*10, '-', FLOOR(Age/10)*10+9)
        END AS age_group
    FROM customers
)
SELECT 
    age_group,
    COUNT(*) AS transactions,
    SUM(c.check_amount) AS total_amount
FROM checks c
JOIN age_groups a ON c.ID_client = a.Id_client
WHERE c.date_new >= '2015-06-01'
  AND c.date_new < '2016-06-01'
GROUP BY age_group;


# Gender
WITH checks AS (
    SELECT 
        Id_check,
        ID_client,
        date_new,
        SUM(Sum_payment) AS check_amount
    FROM transactions
    GROUP BY Id_check, ID_client, date_new
)
SELECT 
    DATE_FORMAT(c.date_new, '%Y-%m') AS month,
    COALESCE(cu.Gender, 'NA') AS gender,
    COUNT(*) AS transactions,
    SUM(c.check_amount) AS total_spent,
    COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY DATE_FORMAT(c.date_new, '%Y-%m')) AS pct_tx,
    SUM(c.check_amount) / SUM(SUM(c.check_amount)) OVER (PARTITION BY DATE_FORMAT(c.date_new, '%Y-%m')) AS pct_spent
FROM checks c
LEFT JOIN customers cu ON c.ID_client = cu.Id_client
WHERE c.date_new >= '2015-06-01'
  AND c.date_new < '2016-06-01'
GROUP BY month, gender;