/****** Script for SelectTopNRows command from SSMS  ******/
/*

Data cleaning of pizza runner using SQL

*/
select* from customer_orders

-- UPDATE/REMOVE NULL VALUES AND OTHER IN CUSTOMER_ORDERS TABLE
UPDATE customer_orders
SET extras=''
where  extras is null or extras='null'

alter table customer_orders
alter column order_time datetime;

UPDATE customer_orders
SET exclusions=''
where  exclusions is null or exclusions='null'

-- UPDATE/REMOVE NULL VALUES AND OTHER IN CUSTOMER_ORDERS TABLE


update runner_orders
set pickup_time=''
where pickup_time='null'

update runner_orders
set distance=''
where distance='null'

update runner_orders
set duration=''
where duration='null'

update runner_orders
set cancellation=''
where cancellation='null' or cancellation is null


--triming 
UPDATE runner_orders
SET distance = REPLACE(distance, 'km', '')

UPDATE runner_orders
SET duration = REPLACE(REPLACE(REPLACE(duration, 'mins', ''), 'minute', ''), 'minutes', '')
WHERE  duration LIKE '%mins%';

UPDATE runner_orders
SET duration = REPLACE(REPLACE(REPLACE(duration, 's', ''), 's', ''), 's', '')
WHERE  duration LIKE '%s%';

alter table runner_orders
alter column pickup_time Datetime;

alter table runner_orders
alter column DISTANCE FLOAT;

alter table runner_orders
alter column DURATION INT;



--pizza name in pizza_names
alter table [dbo].[pizza_names]
alter column pizza_name varchar(20)

ALTER TABLE PIZZA_RECIPES
ALTER COLUMN TOPPINGS VARCHAR(50);

ALTER TABLE cleaned_toppings
ALTER COLUMN topping_name VARCHAR(50);



