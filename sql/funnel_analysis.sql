CREATE DATABASE ecommerce_project;
USE ecommerce_project;

CREATE TABLE ecommerce_data (

    customer_id INT,

    purchase_date TEXT,

    product_category TEXT,

    product_price DOUBLE,

    quantity INT,

    total_purchase_amount DOUBLE,

    payment_method TEXT,

    customer_age INT,

    returns TEXT,

    customer_name TEXT,

    age INT,

    gender TEXT,
    
    churn INT

);

SELECT * FROM ecommerce_data;
SELECT COUNT(*) FROM ecommerce_data;

SELECT *
FROM ecommerce_data
LIMIT 10;

SELECT COUNT(DISTINCT customer_id)
FROM ecommerce_data;

SELECT DISTINCT product_category
FROM ecommerce_data;

SELECT DISTINCT payment_method
FROM ecommerce_data;

/* CUSTOMER PURCHASE COUNTS */

SELECT
    customer_id,
    COUNT(*) AS total_orders
FROM ecommerce_data
GROUP BY customer_id;

/* FUNNEL ANALYSIS */
WITH customer_orders AS (

    SELECT
        customer_id,
        COUNT(*) AS total_orders,
        MAX(churn) AS churn_status

    FROM ecommerce_data
    GROUP BY customer_id
)
SELECT

    COUNT(DISTINCT customer_id) AS visitors,

    COUNT(DISTINCT CASE
        WHEN total_orders >= 1
        THEN customer_id
    END) AS interested,

    COUNT(DISTINCT CASE
        WHEN total_orders >= 2
        THEN customer_id
    END) AS engaged,

    COUNT(DISTINCT CASE
        WHEN total_orders >= 5
        THEN customer_id
    END) AS loyal,

    COUNT(DISTINCT CASE
        WHEN churn_status = 0
        THEN customer_id
    END) AS retained

FROM customer_orders;

/* CONVERSION RATES */
WITH customer_orders AS (

    SELECT
        customer_id,
        COUNT(*) AS total_orders,
        MAX(churn) AS churn_status

    FROM ecommerce_data
    GROUP BY customer_id
),

funnel AS (

    SELECT

        COUNT(DISTINCT customer_id) AS visitors,

        COUNT(DISTINCT CASE
            WHEN total_orders >= 1
            THEN customer_id
        END) AS interested,

        COUNT(DISTINCT CASE
            WHEN total_orders >= 2
            THEN customer_id
        END) AS engaged,

        COUNT(DISTINCT CASE
            WHEN total_orders >= 5
            THEN customer_id
        END) AS loyal,

        COUNT(DISTINCT CASE
            WHEN churn_status = 0
            THEN customer_id
        END) AS retained

    FROM customer_orders
)

SELECT *,

ROUND(interested * 100.0 / visitors,2) AS visit_to_interest_rate,

ROUND(engaged * 100.0 / interested,2) AS interest_to_engaged_rate,

ROUND(loyal * 100.0 / engaged,2) AS engaged_to_loyal_rate,

ROUND(retained * 100.0 / visitors,2) AS retention_rate

FROM funnel;

/*DROP-OFF CUSTOMERS*/
WITH customer_orders AS (

    SELECT
        customer_id,
        COUNT(*) AS total_orders

    FROM ecommerce_data
    GROUP BY customer_id
)

SELECT *
FROM customer_orders
WHERE total_orders = 1;

/* PURCHASE SEQUENCE */
SELECT
    customer_id,
    purchase_date,
    total_purchase_amount,

    ROW_NUMBER() OVER(
        PARTITION BY customer_id
        ORDER BY purchase_date
    ) AS purchase_number

FROM ecommerce_data;

/*FINDING PREVIOUSE PURCHASES*/
SELECT
    customer_id,
    purchase_date,
    total_purchase_amount,

    LAG(total_purchase_amount)
    OVER(
        PARTITION BY customer_id
        ORDER BY purchase_date
    ) AS previous_purchase

FROM ecommerce_data;

/*FINDING NEXT PURCHASES*/
SELECT
    customer_id,
    purchase_date,
    total_purchase_amount,

    LEAD(total_purchase_amount)
    OVER(
        PARTITION BY customer_id
        ORDER BY purchase_date
    ) AS next_purchase

FROM ecommerce_data;


/*CUSTOMEMR LIFETIME VALUE (CLV) */

SELECT
    customer_id,
    SUM(total_purchase_amount) AS lifetime_value
FROM ecommerce_data
GROUP BY customer_id
ORDER BY lifetime_value DESC;


/* MONTHLY REVENUE TREND */
SELECT
    DATE_FORMAT(purchase_date,'%Y-%m') AS month,
    SUM(total_purchase_amount) AS revenue
FROM ecommerce_data
GROUP BY month
ORDER BY month;

/*FINDING CUSTOMER COHORT*/
WITH first_purchase AS (

    SELECT
        customer_id,
        MIN(purchase_date) AS first_purchase_date

    FROM ecommerce_data
    GROUP BY customer_id
)

SELECT
    customer_id,

    DATE_FORMAT(first_purchase_date,'%Y-%m') AS cohort_month

FROM first_purchase;


/*RETENTION ANALYSIS*/
WITH first_purchase AS (

    SELECT
        customer_id,
        MIN(purchase_date) AS first_purchase_date

    FROM ecommerce_data
    GROUP BY customer_id
),

customer_activity AS (

    SELECT
        e.customer_id,

        DATE_FORMAT(f.first_purchase_date,'%Y-%m') AS cohort_month,

        DATE_FORMAT(e.purchase_date,'%Y-%m') AS activity_month

    FROM ecommerce_data e
    JOIN first_purchase f
    ON e.customer_id = f.customer_id
)

SELECT
    cohort_month,
    activity_month,

    COUNT(DISTINCT customer_id) AS active_customers

FROM customer_activity
GROUP BY cohort_month, activity_month
ORDER BY cohort_month, activity_month;

/*BEST PRODUCT CATEGORY*/
SELECT
    product_category,
    SUM(total_purchase_amount) AS revenue
FROM ecommerce_data
GROUP BY product_category
ORDER BY revenue DESC;

/*RETURN ANALYSIS*/
SELECT
    product_category,
    AVG(returns) * 100 AS return_rate
FROM ecommerce_data
GROUP BY product_category
ORDER BY return_rate DESC;


/*CHURN ANALYSIS*/
SELECT
    gender,
    AVG(churn) * 100 AS churn_rate
FROM ecommerce_data
GROUP BY gender;


/*AVERAGE ORDER VALUE*/
SELECT
    AVG(total_purchase_amount) AS avg_order_value
FROM ecommerce_data;


/*HIGHEST SPENDIND CUSTOMERS*/
SELECT
    customer_id,
    customer_name,
    SUM(total_purchase_amount) AS total_spent
FROM ecommerce_data
GROUP BY customer_id, customer_name
ORDER BY total_spent DESC
LIMIT 10;
