/*
Data analysis using SQL 
*/

/*
--------------------------------------------------------------------------------------


                             A. Customer Nodes Exploration


--------------------------------------------------------------------------------------

*/

--------------------------------------------------------------------------------------
--Q(1) How many unique nodes are there on the Data Bank system?

SELECT count(distinct node_id) as unique_nodes
FROM [dbo].[customer_nodes]

--------------------------------------------------------------------------------------
--Q(2) What is the number of nodes per region?

SELECT region_name,COUNT(NODE_ID) AS number_nodes
FROM [dbo].[customer_nodes] cn
join regions r on cn.region_id=r.region_id
group by region_name
order by number_nodes desc

--------------------------------------------------------------------------------------
--Q(3) How many customers are allocated to each region?

SELECT region_name,COUNT(distinct customer_id) AS customers_count
FROM [dbo].[customer_nodes] cn
join regions r on cn.region_id=r.region_id
group by region_name
order by customers_count desc

--------------------------------------------------------------------------------------
--Q(4) How many days on average are customers reallocated to a different node?

SELECT abs(avg(datediff(day,end_date, start_date))) AS avg_days
FROM customer_nodes
WHERE end_date!='9999-12-31';

--------------------------------------------------------------------------------------
--Q(5) What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

SELECT
  region_name,
  median,
  p_8,
  p_95
FROM (
  SELECT
    region_name,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ABS(DATEDIFF(day, end_date, start_date))) OVER (PARTITION BY region_name) AS median,
    PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY ABS(DATEDIFF(day, end_date, start_date))) OVER (PARTITION BY region_name) AS p_8,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY ABS(DATEDIFF(day, end_date, start_date))) OVER (PARTITION BY region_name) AS p_95
  FROM
    [dbo].[customer_nodes] cn
    JOIN regions r ON cn.region_id = r.region_id
  WHERE
    end_date <> '9999-12-31'
) subquery
GROUP BY
  region_name,median, p_8, p_95;


--------------------------------------------------------------------------------------

/*
--------------------------------------------------------------------------------------


                             B. Customer Transactions


--------------------------------------------------------------------------------------

*/

---------------------------------------------------------------------------------------
--Q(1) What is the unique count and total amount for each transaction type?

SELECT txn_type, count(*) as unique_count, sum(txn_amount) as total_amount
from customer_transactions
group by txn_type
---------------------------------------------------------------------------------------
--Q(2) What is the average total historical deposit counts and amounts for all customers?

select top 1 txn_type,
avg(counts) as avg_hist_counts,
avg(amounts) as avg_amounts
from(
select customer_id ,txn_type,count(txn_type) as counts, sum(txn_amount) as amounts
from [dbo].[customer_transactions]
group by customer_id,txn_type
) subquery
where txn_type like '%deposit'
group by txn_type

---------------------------------------------------------------------------------------
--Q(3) For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?

WITH customer_counts AS (
      select   DATEPART(MONTH, TXN_DATE) AS month_no,
    customer_id,
    sum(CASE WHEN txn_type LIKE '%deposit' THEN 1 ELSE 0 END) AS deposit_count,
    sum(CASE WHEN txn_type LIKE '%purchase' THEN 1 ELSE 0 END) AS purchase_count,
    sum(CASE WHEN txn_type LIKE '%withdrawal' THEN 1 ELSE 0 END) AS withdrawal_count
FROM
    CUSTOMER_TRANSACTIONS
GROUP BY
    DATEPART(MONTH, TXN_DATE),
    customer_id
        
)
SELECT
    month_no,
    COUNT(*) AS customers
FROM
    customer_counts
WHERE
    deposit_count > 1
    AND (purchase_count >= 1 OR withdrawal_count >= 1)
GROUP BY
    month_no
ORDER BY
    month_no;
 
--------------------------------------------------------------------------------------
--Q(4) What is the closing balance for each customer at the end of the month?
WITH txn_monthly_balance_cte AS
  (SELECT top 100 percent customer_id,
          Datepart(month,txn_date) AS txn_month,
          SUM(CASE
                  WHEN txn_type like '%deposit' THEN txn_amount
                  ELSE -txn_amount
              END) AS net_transaction_amt
   FROM customer_transactions
   GROUP BY customer_id,
            Datepart(month,txn_date)
   ORDER BY customer_id)
SELECT customer_id,
       txn_month,
       net_transaction_amt,
       sum(net_transaction_amt) over(PARTITION BY customer_id
                                     ORDER BY txn_month ROWS BETWEEN UNBOUNDED preceding AND CURRENT ROW) AS closing_balance
FROM txn_monthly_balance_cte;



--------------------------------------------------------------------------------------
--Q(5) What is the percentage of customers who increase their closing balance by more than 5%?
WITH cte AS
(
    SELECT
        customer_id,
        DATEADD(MONTH, DATEDIFF(MONTH, 0, txn_date), 0) AS month_start,
        SUM(CASE WHEN txn_type like  '%deposit' THEN txn_amount ELSE -1 * txn_amount END) AS total_amount
    FROM
        customer_transactions
    GROUP BY
        customer_id, DATEADD(MONTH, DATEDIFF(MONTH, 0, txn_date), 0)
)
SELECT
    COUNT(DISTINCT CASE WHEN closing_balance_increase > 0.05 THEN customer_id END) AS customers_with_increase,
    COUNT(DISTINCT customer_id) AS total_customers,
    100 * COUNT(DISTINCT CASE WHEN closing_balance_increase > 0.05 THEN customer_id END) / COUNT(DISTINCT customer_id) AS percentage_increase
FROM
    (
        SELECT
            cte.customer_id,
            SUM(cte.total_amount) OVER (PARTITION BY cte.customer_id ORDER BY cte.month_start) AS closing_balance,
            (SUM(cte.total_amount) OVER (PARTITION BY cte.customer_id ORDER BY cte.month_start) - LAG(SUM(cte.total_amount))
			OVER (PARTITION BY cte.customer_id ORDER BY cte.month_start)) / LAG(SUM(cte.total_amount))
			OVER (PARTITION BY cte.customer_id ORDER BY cte.month_start) AS closing_balance_increase
        FROM
            cte
        GROUP BY
            cte.customer_id, cte.month_start,cte.total_amount -- Add customer_id to the GROUP BY clause
    
    ) AS subquery;

-------------------------------------------------------------------------------------------------
