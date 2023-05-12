/*
DATA ANALYSIS OF PIZZA RUNNER USING PYTHON

*/
---------------------------------------------------------------------------

/*                         A.PIZZA Metrics                    */

---------------------------------------------------------------------------


--Q(1) How many pizzas were ordered?

select count(pizza_id) as ordered_pizzas
from customer_orders 

---------------------------------------------------------------------------

--Q(2) How many unique customer orders were made?

select count(Distinct order_id) as unique_orders
from customer_orders

----------------------------------------------------------------------------
--Q(3) How many successful orders were delivered by each runner?

select runner_id,count(order_id) as success_orders
from runner_orders
where cancellation not like '%cancellation%'
group by runner_id 

----------------------------------------------------------------------------
--Q(4) How many of each type of pizza was delivered?

select pizza_name, count(c.pizza_id) as total_delivered
from customer_orders c 
left join pizza_names p on c.pizza_id=p.pizza_id
join runner_orders r on r.order_id=c.order_id
where r.cancellation=''
group by pizza_name

----------------------------------------------------------------------------
--Q(5) How many Vegetarian and Meatlovers were ordered by each customer?

select customer_id,pizza_name, count(c.pizza_id) as total_ordered
from customer_orders c 
left join pizza_names p on c.pizza_id=p.pizza_id
group by pizza_name,customer_id

----------------------------------------------------------------------------
--Q(6) What was the maximum number of pizzas delivered in a single order?

with maximum as 
(select TOP 100 PERCENT order_id, count(pizza_id) as maxi
from customer_orders
group by order_id
order by maxi desc)

select MAX(maxi) as maximum_pizza_in_single_order
from maximum
----------------------------------------------------------------------------
--Q(7) For each customer, how many delivered pizzas had at least 1 change and how many had no changes? 

select c.customer_id,sum(case when exclusions!='' or  extras!='' then 1 else 0 end ) as change,
sum(case when exclusions='' and extras='' then 1 else 0 end ) as no_changes
from customer_orders c
left join runner_orders r on c.order_id=r.order_id
where r.cancellation=''
group by c.customer_id

----------------------------------------------------------------------------
--Q(8) How many pizzas were delivered that had both exclusions and extras?
select  count(c.pizza_id) as pizza_count
from customer_orders c
left join runner_orders r on c.order_id=r.order_id
where exclusions!='' and extras!='' and r.cancellation=''

----------------------------------------------------------------------------
--Q(9) What was the total volume of pizzas ordered for each hour of the day?

select DATEPART(HOUR,order_time) as hour_of_day,COUNT(pizza_id) as pizza_volume
from customer_orders
group by DATEPART(HOUR,order_time)

----------------------------------------------------------------------------
--Q(10) What was the volume of orders for each day of the week?

select DATENAME(WEEKDAY,order_time) AS DAY_OF_WEEK, count(order_id) as orders
from [dbo].[customer_orders]
group by DATENAME(WEEKDAY,order_time)

----------------------------------------------------------------------------

----------------------------------------------------------------------------

/*                        B. Runner and Customer Experience                   */

----------------------------------------------------------------------------
--Q(1) How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

SELECT DATEPART(WEEK,registration_date) as weeks, count(*) as runners
from [dbo].[runners]
group by DATEPART(WEEK,registration_date)

----------------------------------------------------------------------------
--Q(2) What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

WITH TIMES AS
(select top 100 percent r.runner_id,(ABS(datepart(MINUTE,order_time)-DATEPART(MINUTE,pickup_time))) as duration
from customer_orders c
join runner_orders r on c.order_id=r.order_id
where cancellation='')

SELECT runner_id,ROUND(AVG(DURATION),0) AS AVG_TIME
FROM TIMES
group by runner_id

----------------------------------------------------------------------------
--Q(3) Is there any relationship between the number of pizzas and how long the order takes to prepare?

WITH cte_pizza AS (
	SELECT
		c.order_id,
		COUNT(c.order_id) AS num_pizza,
       ABS(Datediff(minute,pickup_time,order_time)) as time_diff
	FROM runner_orders r
    JOIN customer_orders c ON c.order_id = r.order_id
    WHERE distance != 0
    GROUP BY c.order_id,pickup_time,order_time)
SELECT
	num_pizza,
    avg(time_diff) AS avg_prepare_time
FROM cte_pizza
GROUP BY num_pizza;

----------------------------------------------------------------------------
--Q(4) What was the average distance travelled for each customer?

select customer_id,round(avg(distance),2) as avg_distance
FROM customer_orders c
left join runner_orders r on c.order_id=r.order_id
group by customer_id

----------------------------------------------------------------------------
--Q(5) What was the difference between the longest and shortest delivery times for all orders?
WITH cte_pizza AS (
	SELECT
		c.order_id,
       ABS(Datediff(minute,pickup_time,order_time)) as duration
	FROM runner_orders r
    JOIN customer_orders c ON c.order_id = r.order_id
    WHERE duration!=''
    GROUP BY c.order_id,pickup_time,order_time)

select max(duration)-min(duration) as time_diff
from cte_pizza

-----------------------------------------------------------------------------
--Q(6) What was the average speed for each runner for each delivery and do you notice any trend for these values?
WITH cte_order AS (
	SELECT 
		order_id,
        COUNT(pizza_id) AS total_pizza
	FROM customer_orders
    GROUP BY order_id)
SELECT
	tro.runner_id,
    tro.order_id,
    tro.distance,
    tro.duration,
    co.total_pizza,
    ROUND(60 * distance / duration, 1) AS speedKmH
FROM runner_orders tro
JOIN cte_order co ON co.order_id = tro.order_id
WHERE distance != ''
GROUP BY tro.runner_id, tro.order_id,distance,duration,co.total_pizza
ORDER BY tro.runner_id;

-------------------------------------------------------------------------------------
--Q(7) What is the successful delivery percentage for each runner?
WITH runner_stats AS (
  SELECT 
    runner_id, 
    COUNT(*) AS total_orders, 
    SUM(CASE WHEN cancellation='' THEN 1 ELSE 0 END) AS successful_orders
  FROM runner_orders
  GROUP BY runner_id
)
SELECT 
  runner_id, 
  successful_orders, 
  total_orders, 
  successful_orders * 100 / total_orders AS perc_delivery
FROM runner_stats;

-------------------------------------------------------------------------------------

---------------------------------------------------------------------------

/*                         C. Ingredient Optimisation                    */

---------------------------------------------------------------------------

--Q(1) What are the standard ingredients for each pizza?

SELECT pn.pizza_id,
       pn.pizza_name,
       pt.topping_name
FROM pizza_recipes pr
JOIN pizza_names pn ON pr.pizza_id = pn.pizza_id
CROSS APPLY STRING_SPLIT(pr.toppings, ',') s
JOIN pizza_toppings pt ON s.value = pt.topping_id;

---------------------------------------------------------------------------
-- Q(2 )What was the most commonly added extra?
with cte as
(SELECT top 100 percent trim(s.value) as exclude_no,count(*) as total
FROM customer_orders c
CROSS APPLY STRING_SPLIT(c.extras, ',') s 
WHERE c.extras <> ''
group by trim(s.value))

select topping_name,total as extras_count
from cte c
JOIN pizza_toppings p ON c.exclude_no = p.topping_id
order by extras_count desc
--------------------------------------------------------------------------
--Q(3)What was the most commonly added EXCLUSIONS?with cte as
with cte as
(SELECT top 100 percent trim(s.value) as exclude_no,count(*) as total
FROM customer_orders c
CROSS APPLY STRING_SPLIT(c.exclusions, ',') s 
WHERE c.exclusions <> ''
group by trim(s.value))

select topping_name,total as excluded_count
from cte c
JOIN pizza_toppings p ON c.exclude_no = p.topping_id
order by excluded_count desc
----------------------------------------------------------------------------
/*Q(4) Generate an order item for each record in the customers_orders table in the format of one of the following:
Meat Lovers(
Meat Lovers - Exclude Beef
Meat Lovers - Extra Bacon
Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers)?

*/

SELECT
	tco.order_id,
    tco.pizza_id,
    pn.pizza_name,
    tco.exclusions,
    tco.extras,
    CASE
		WHEN tco.pizza_id = 1 AND tco.exclusions = '' AND tco.extras = '' THEN 'Meat Lovers'
        WHEN tco.pizza_id = 2 AND tco.exclusions = '' AND tco.extras = '' THEN 'Vegetarian'
        WHEN tco.pizza_id = 1 AND tco.exclusions = '4' AND tco.extras = '' THEN 'Meat Lovers - Exclude Cheese'
        WHEN tco.pizza_id = 2 AND tco.exclusions = '4' AND tco.extras = '' THEN 'Vegetarian - Exclude Cheese'
        WHEN tco.pizza_id = 1 AND tco.exclusions = '' AND tco.extras = '1' THEN 'Meat Lovers - Extra Bacon'
        WHEN tco.pizza_id = 2 AND tco.exclusions = '' AND tco.extras = '1' THEN 'Vegetarian - Extra Bacon'
        WHEN tco.pizza_id = 1 AND tco.exclusions = '4' AND tco.extras = '1, 5' THEN 'Meat Lovers - Exclude Cheese - Extra Bacon and Chicken'
        WHEN tco.pizza_id = 1 AND tco.exclusions = '2, 6' AND tco.extras = '1, 4' THEN 'Meat Lovers - Exclude BBQ Sauce and Mushroom - Extra Bacon and Cheese'
	END AS order_item
FROM customer_orders tco
JOIN pizza_names pn ON tco.pizza_id = pn.pizza_id;
----------------------------------------------------------------------------------------
/*Q(5)
Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
*/ 

Alter table customer_orders
add record_id INT identity(1,1);
drop table if exists extras
select c.record_id,TRIM(s.value) as topp_id
into extras
FROM customer_orders c
CROSS APPLY STRING_SPLIT(c.extras, ',') s 
where extras<>''

drop table if exists exclusions
select c.record_id,TRIM(s.value) as topp_id
into exclusions
FROM customer_orders c
CROSS APPLY STRING_SPLIT(c.exclusions, ',') s 
where exclusions<>''

 SELECT		
   p.pizza_id,
   TRIM(t.value) AS topping_id,
   pt.topping_name
 INTO cleaned_toppings
 FROM 
     pizza_recipes as p
     CROSS APPLY string_split(p.toppings, ',') as t
     JOIN pizza_toppings as pt
     ON TRIM(t.value) = pt.topping_id 
 ;

--query



WITH ingredients_cte AS
(
	SELECT
	c.record_id, 
	p.pizza_name,
	CASE
		WHEN t.topping_id 
		IN (select topping_id from extras e where c.record_id = e.record_id)
		THEN concat('2x' , t.topping_name)
		ELSE t.topping_name
	END as topping
	FROM 
		customer_orders c
		JOIN pizza_names p
			ON c.pizza_id = p.pizza_id
		JOIN cleaned_toppings t 
			ON c.pizza_id = t.pizza_id
	WHERE t.topping_id NOT IN (select topp_id from exclusions e where c.record_id = e.record_id)
)

SELECT 
	record_id,
	CONCAT(pizza_name,':',string_agg(CAST(topping AS varchar(max)),',')) as ingredients_list
FROM ingredients_cte
GROUP BY 
	record_id,
	pizza_name
ORDER BY 1;
-------------------------------------------------------------------------------------

--Q(6) What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

select topping_name,count(*) as total_time
from customer_orders c
join runner_orders r on c.order_id=r.order_id join cleaned_toppings ct on ct.pizza_id=c.pizza_id
where cancellation=''
group by topping_name
order by  total_time desc

-------------------------------------------------------------------------------------
---------------------------------------------------------------------------

/*                         D. Pricing and Ratings                   */

---------------------------------------------------------------------------
--Q(1) If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - 
--how much money has Pizza Runner made so far if there are no delivery fees?

select  sum(case when pizza_name='Meatlovers' then 12
                    else 10 end ) as total_money_made
from customer_orders c 
join runner_orders r on c.order_id=r.order_id join pizza_names p on c.pizza_id=p.pizza_id
where cancellation=''

-----------------------------------------------------------------------------------
--Q(2)What if there was an additional $1 charge for any pizza extras?
--Add cheese is $1 extra
 
 with cte as
(select  topping_name,count(*) as total,sum(case when pizza_name='Meatlovers' then 12
                    else 10 end ) as total_money_made
from customer_orders c 
join runner_orders r on c.order_id=r.order_id join pizza_names p on c.pizza_id=p.pizza_id join cleaned_toppings t on t.pizza_id=c.pizza_id
where cancellation=''
and topping_name='cheese' 
group by topping_name)

select ((total*1)+total_money_made) as total_money_with_cheese
from cte 

----------------------------------------------------------------------------------
--Q(3) The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, 
--how would you design an additional table for this new dataset - generate a schema for this new table and 
--insert your own data for ratings for each successful customer order between 1 to 5.



CREATE TABLE runner_ratings (
  rating_id INT IDENTITY(1, 1) PRIMARY KEY,
  order_id INT NULL,
  runner_id INT NOT NULL,
  customer_id INT NOT NULL,
  rating INT NOT NULL
);

INSERT INTO runner_ratings (order_id, runner_id,customer_id, rating)
values (1, 1, 101,2),
  (10, 2, 104,1),
  (7, 3, 105,3),
  (8, 1, 102,4),
  (3, 2, 102,5);

---------------------------------------------------------------------------------
/*
Q(4)Using your newly generated table - 
can you join all of the information together to form a table which has the following information for successful deliveries?
customer_id
order_id
runner_id
rating
order_time
pickup_time
Time between order and pickup
Delivery duration
Average speed
Total number of pizzas

*/

select c.customer_id,c.order_id,rn.runner_id,rating,order_time,pickup_time,concat((DATEDIFF(MINUTE,order_time,pickup_time)),' mins') as time_between_order_and_pick
,duration,ROUND(60 * distance / duration, 1) AS avg_speed_KmH, count(c.pizza_id) as total_num_pizzas
FROM customer_orders c
join runner_orders rn on c.order_id=rn.order_id join runner_ratings rt on rt.customer_id=c.customer_id
where cancellation='' and distance!=''
group by c.customer_id,c.order_id,rn.runner_id,order_time,pickup_time,duration,distance,rating

---------------------------------------------------------------------------------------------------------------

/*Q(5) 

If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with
no cost for extras and each runner is paid $0.30 per kilometre traveled 
-how much money does Pizza Runner have left over after these deliveries?

*/
with cte_left as
(select top 100 percent c.order_id, sum(case when pizza_name='Meatlovers' then 12
         else 10 end) as total_price
FROM CUSTOMER_ORDERS C
join runner_orders r on c.order_id=r.order_id join pizza_names p on p.pizza_id=c.pizza_id
where cancellation=''
group by c.order_id)

select round((sum(total_price)-(sum(duration))*0.30),0) as sum_value
from  cte_left c
join runner_orders r on c.order_id=r.order_id

-------------------------------------------------------------------------------

/*  

--E.BONUS QUESTION
If Danny wants to expand his range of pizzas - 
how would this impact the existing data design? 
Write an INSERT statement to demonstrate 
what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?


*/



Insert into pizza_names(pizza_id,pizza_name)
values (3,'Supreme_Pizza')

Insert into pizza_recipes(pizza_id,toppings)
values (3,'1,2,3,4,5,6,7,8,9,10,11,12')

/*
Specifically, the database would need to be updated to include information about the new pizza and its toppings.

the new pizza would need to be added to the "pizza_names" table with a new ID and name, and in "pizza_recipes"
The toppings for the new pizza would also need to be added to the "toppings" table if they are not already there.
*/
-------------------------------------------------------------------------------
