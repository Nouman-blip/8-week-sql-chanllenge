/*

DATA ANLYSIS OF FOODIE-FI STREAMING CHANNEL USING SQL

*/

-----------------------------------------------------------------------------

/*                                  A. Customer Journey                          */

-----------------------------------------------------------------------------

select  s.customer_id,start_date,plan_name,price
from subscriptions s 
join plans p on s.plan_id=p.plan_id
where customer_id in(1,2,3,5,6,205,300,19)

/* 
I select random or sample of 8 customers 1,2,3,5,6,205,300,19
--CUSTOMER ID 1 START HIS/HER trial at 2020-08-01 with price 0 and after using it 7 days he was interesting in it and
buys basic montly 9.90 price

--CUSTOMER ID 2 START HIS/HER trial at 2020-09-20 with price 0 and after using it 7 days he was interesting in it and
buys pro annual 199.00 price

--CUSTOMER ID 3 START HIS/HER trial at 2020-01-13 with price 0 and after using it 7 days he was interesting in it and
buys pro annual 9.90 price
....................................
*/

-----------------------------------------------------------------------------

/*                                  B. Data Analysis Questions                         */

-----------------------------------------------------------------------------
--Q(1) How many customers has Foodie-Fi ever had?

select  count(distinct customer_id) as total_customer
from subscriptions s 
join plans p on s.plan_id=p.plan_id

-----------------------------------------------------------------------------
--Q(2) What is the monthly distribution of trial plan start_date values for our dataset - 
--use the start of the month as the group by value

select DATEPART(MONTH,start_date)as month_no,count(start_date) as start_date_values
from subscriptions s 
join plans p on s.plan_id=p.plan_id
where plan_name='trial'
group by DATEPART(MONTH,start_date)

------------------------------------------------------------------------------
--Q(3) What plan start_date values occur after the year 2020 for our dataset?
--Show the breakdown by count of events for each plan_name

select plan_name ,count(*) as total_plan
from subscriptions s
join plans p on s.plan_id=p.plan_id
where DATEPART(YEAR,start_date)>'2020'
group by plan_name

------------------------------------------------------------------------------
--Q(4) What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

with cte as
(select count( distinct customer_id) as total_customer,
COUNT(DISTINCT CASE WHEN p.plan_name = 'churn' THEN s.customer_id END) AS churn_customer
from subscriptions s
join plans p on s.plan_id=p.plan_id)

select round(cast(churn_customer as float)/cast(total_customer as float)*100,1) as round_1decimals
from cte

------------------------------------------------------------------------------
--Q(5) How many customers have churned straight after their initial free trial -
--what percentage is this rounded to the nearest whole number?


with cte as
    (select s.*,plan_name,lead(plan_name,1) over(partition by customer_id order by start_date) as same
    from subscriptions s
    join plans p on s.plan_id=p.plan_id
),
cte2 as
(select count( case when same='churn' and plan_name='trial' then customer_id end ) as cust_count,count(distinct customer_id) as total
from cte)

select round((CAST(cust_count as float)/cast(total as float))*100,1)  as churn_percentage_round
from cte2
---------------------------------------------------------------------------------------------
--Q(6) What is the number and percentage of customer plans after their initial free trial?

with cte as
    (select s.*,plan_name,lead(plan_name,1) over(partition by customer_id order by start_date) as same
    from subscriptions s
    join plans p on s.plan_id=p.plan_id
),
cte2 as
(SELECT COUNT(distinct CASE WHEN plan_name = 'trial' AND same = 'basic monthly' THEN customer_id END) AS total_basic,
	COUNT(distinct CASE WHEN plan_name = 'trial' AND same = 'pro monthly' THEN customer_id END) AS total_pro, 
	COUNT(distinct CASE WHEN plan_name = 'trial' AND same = 'pro annual' THEN customer_id END) AS total_annual,
	COUNT(distinct CASE WHEN plan_name = 'trial' AND same = 'churn' THEN customer_id END) AS total_churn
	FROM CTE
) 
SELECT *, ROUND(cast((total_basic) as numeric)/1000 * 100, 0) AS basic_pct, 
ROUND(cast((total_pro) as numeric)/1000 * 100, 0) AS pro_pct, 
ROUND(cast((total_annual) as numeric)/1000 * 100, 0) AS annual_pct,
ROUND(cast((total_churn) as numeric)/1000 * 100, 0) AS churn_pct
FROM CTE2


---------------------------------------------------------------------------------------------
--Q(7) What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
with cte as
(select count(customer_id) as total_customer, count(case when plan_name='trial' then customer_id end) as trial_plan,
count( case when plan_name='basic monthly' then customer_id end) as basic_monthly,
count(case when plan_name='pro monthly' then customer_id end) as pro_monthly,
count(case when plan_name='pro annual' then customer_id end) as pro_annual,
count(case when plan_name='churn' then customer_id end) as churn
from subscriptions s
join plans p on s.plan_id=p.plan_id
where start_date<='2020-12-31')

select total_customer,ROUND(cast((trial_plan) as numeric)/total_customer * 100, 1) AS trial_pct, 
ROUND(cast((basic_monthly) as numeric)/total_customer * 100, 1) AS basic_month_pct, 
ROUND(cast((pro_monthly) as numeric)/total_customer * 100, 1) AS pro_monthly_pct,
ROUND(cast((pro_annual) as numeric)/total_customer * 100, 1) AS pro_annual_pct,
ROUND(cast((churn) as numeric)/total_customer * 100, 1) AS churn_pct
from cte
--------------------------------------------------------------------------------------
--Q(8) How many customers have upgraded to an annual plan in 2020?

select count(distinct customer_id) as total
from subscriptions s
join plans p on s.plan_id=p.plan_id
where DATEPART(Year,start_date)='2020'
and plan_name='pro annual'

-------------------------------------------------------------------------------------
--Q(9) How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
SELECT AVG(DATEDIFF(day, start_date, start_annual)) AS average_day
FROM (
  SELECT customer_id, start_date
  FROM subscriptions s
  join plans p on s.plan_id=p.plan_id
  WHERE plan_name = 'trial'
) AS start_cte
LEFT JOIN (
  SELECT customer_id, start_date AS start_annual
  FROM subscriptions  s
  join plans p on s.plan_id=p.plan_id
  WHERE plan_name = 'pro annual'
) AS annual_cte
ON start_cte.customer_id = annual_cte.customer_id;
---------------------------------------------------------------------------------------------
--Q(10) Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
 select CASE 
    WHEN DATEDIFF(day, start_date, start_annual) BETWEEN 0 AND 30 THEN '0-30'
    WHEN DATEDIFF(day, start_date, start_annual) BETWEEN 31 AND 60 THEN '31-60'
    WHEN DATEDIFF(day, start_date, start_annual) BETWEEN 61 AND 90 THEN '61-90'
    WHEN DATEDIFF(day, start_date, start_annual) BETWEEN 91 AND 120 THEN '91-120'
    WHEN DATEDIFF(day, start_date, start_annual) BETWEEN 121 AND 150 THEN '121-150'
    WHEN DATEDIFF(day, start_date, start_annual) BETWEEN 151 AND 180 THEN '151-180'
    WHEN DATEDIFF(day, start_date, start_annual) BETWEEN 181 AND 210 THEN '181-210'
    WHEN DATEDIFF(day, start_date, start_annual) BETWEEN 211 AND 240 THEN '211-240'
    WHEN DATEDIFF(day, start_date, start_annual) BETWEEN 241 AND 270 THEN '241-270'
    WHEN DATEDIFF(day, start_date, start_annual) > 270 THEN '271-300'
  END AS dayss,
  COUNT(*) AS number_of_customers,
  AVG(DATEDIFF(day, start_date, start_annual)) AS average_day
FROM (
  SELECT customer_id, start_date
  FROM subscriptions s
  join plans p on s.plan_id=p.plan_id
  WHERE plan_name = 'trial'
) AS start_cte
LEFT JOIN (
  SELECT customer_id, start_date AS start_annual
  FROM subscriptions  s
  join plans p on s.plan_id=p.plan_id
  WHERE plan_name = 'pro annual'
) AS annual_cte
ON start_cte.customer_id = annual_cte.customer_id
GROUP BY
 case WHEN DATEDIFF(day, start_date, start_annual) BETWEEN 0 AND 30 THEN '0-30'
    WHEN DATEDIFF(day, start_date, start_annual) BETWEEN 31 AND 60 THEN '31-60'
    WHEN DATEDIFF(day, start_date, start_annual) BETWEEN 61 AND 90 THEN '61-90'
    WHEN DATEDIFF(day, start_date, start_annual) BETWEEN 91 AND 120 THEN '91-120'
    WHEN DATEDIFF(day, start_date, start_annual) BETWEEN 121 AND 150 THEN '121-150'
    WHEN DATEDIFF(day, start_date, start_annual) BETWEEN 151 AND 180 THEN '151-180'
    WHEN DATEDIFF(day, start_date, start_annual) BETWEEN 181 AND 210 THEN '181-210'
    WHEN DATEDIFF(day, start_date, start_annual) BETWEEN 211 AND 240 THEN '211-240'
    WHEN DATEDIFF(day, start_date, start_annual) BETWEEN 241 AND 270 THEN '241-270'
    WHEN DATEDIFF(day, start_date, start_annual) > 270 THEN '271-300' end
ORDER BY dayss;

---------------------------------------------------------------------------------------------
--Q(11) How many customers downgraded from a pro monthly to a basic monthly plan in 2020?


--According to query results, no customers downgraded from a pro monthly to a basic monthly plan in 2020.

---------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------

/*                             D. Outside The Box Questions                 */

-----------------------------------------------------------------------------

/*
1.How would you calculate the rate of growth for Foodie-Fi?
ans.

To calculate the rate of growth for Foodie-Fi, I would use the following formula:

Code snippet
(New customers in current month - New customers in previous month) / New customers in previous month

This formula will give me the percentage change in the number of new customers from one month to the next. 
I can then use this percentage change to calculate the rate of growth for Foodie-Fi.
------------------------------------------------------------------------------------------------------------------

2.What key metrics would you recommend Foodie-Fi management to track over time to assess performance of their overall business?

In addition to the rate of growth, I would recommend that Foodie-Fi management track the following key metrics:

Customer acquisition cost (CAC): This is the amount of money that Foodie-Fi spends to acquire a new customer.
Customer lifetime value (CLTV): This is the amount of money that Foodie-Fi can expect to earn from a customer over their lifetime.
Churn rate: This is the percentage of customers who cancel their subscription each month.
Net promoter score (NPS): This is a measure of customer satisfaction.
By tracking these metrics, Foodie-Fi management can get a better understanding of how their business is performing and identify areas where they can improve.
-----------------------------------------------------------------------------------------------------------------------

3.What are some key customer journeys or experiences that you would analyse further to improve customer retention?
Some key customer journeys or experiences that I would analyze further to improve customer retention include:

The sign-up process: Is it easy for customers to sign up for a Foodie-Fi subscription? Are there any steps in the process that could be made easier or more streamlined?
The customer onboarding process: Once customers have signed up, do they have everything they need to get started with Foodie-Fi? Are there any resources or support that they need that they are not getting?
The customer experience: Are customers satisfied with the Foodie-Fi product or service? Are they finding what they are looking for? Are they getting the value that they expect?
By analyzing these customer journeys or experiences, Foodie-Fi can identify areas where they can improve the customer experience and reduce the churn rate.

----------------------------------------------------------------------------------------------------------------------
4.If the Foodie-Fi team were to create an exit survey shown to customers who wish to cancel their subscription, what questions would you include in the survey?

If the Foodie-Fi team were to create an exit survey shown to customers who wish to cancel their subscription, I would include the following questions:

Why are you cancelling your subscription?
What could Foodie-Fi have done to keep you as a customer?
What other streaming services are you considering?
What is your overall satisfaction with Foodie-Fi?
By asking these questions, Foodie-Fi can get valuable feedback from customers who are cancelling their subscriptions.
This feedback can be used to improve the product or service and reduce the churn rate.

-----------------------------------------------------------------------------------------------------------------------

5.What business levers could the Foodie-Fi team use to reduce the customer churn rate? How would you validate the effectiveness of your ideas?

There are a number of business levers that the Foodie-Fi team could use to reduce the customer churn rate. Some of these levers include:

Offering discounts or promotions: This can be a great way to attract new customers and keep existing customers from cancelling their subscriptions.
Improving the customer experience: This can be done by making the sign-up process easier, providing better customer support, and offering more features and benefits.
Personalizing the customer experience: This can be done by sending targeted emails and offers, and by recommending content that is relevant to each customer's interests.
The effectiveness of these ideas can be validated by tracking the churn rate over time. If the churn rate decreases after implementing one of these ideas,
then it can be assumed that the idea was effective.
--------------------------------------------------------------------------------------------------------------------
*/


--------------------------------------------------------------------------------------
