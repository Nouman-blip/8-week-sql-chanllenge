
SELECT * FROM [dannys_diner].[dbo].[members]
Select * from [dbo].[menu]
select * from [dbo].[sales]

/* 
Data analysis of Dannys_diner restaurant Using SQL

*/
---------------------------------------------------------------------------------
-- Q(1): What is the total amount each customer spent at the restaurant?

select s.customer_id,sum(mu.price) as total_amount
from sales s
join menu mu on s.product_id=mu.product_id
group by s.customer_id

---------------------------------------------------------------------------------

-- Q(2): How many days has each customer visited the restaurant?

select customer_id, count(Distinct order_date) as visited_days
from sales
group by customer_id


---------------------------------------------------------------------------------
-- Q(3): What was the first item from the menu purchased by each customer?
with ranks as
(select s.*,mu.product_name,row_number() over(partition by s.customer_id order by s.order_date) as rank_no
from sales s
left join menu mu on s.product_id=mu.product_id)


SELECT 
  customer_id, 
  product_name AS first_item
FROM ranks
WHERE 
  rank_no = 1
  

---------------------------------------------------------------------------------
-- Q(4): What is the most purchased item on the menu and how many times was it purchased by all customers?


select TOP 1 s.product_id, mu.product_name AS most_purchased_item, Count(*) as total_purchased_by_customers
from sales s
join menu mu on s.product_id=mu.product_id
group by s.product_id,mu.product_name
order by s.product_id desc

---------------------------------------------------------------------------------
-- Q(5):Which item was the most popular for each customer?
with product_id_count AS
(select  top 7 s.product_id, s.customer_id,MU.PRODUCT_NAME, Count(*) as counts
from sales s
join menu mu on s.product_id=mu.product_id
group by s.product_id,s.customer_id,MU.PRODUCT_NAME
order by S.CUSTOMER_ID ),

ranks as
(select top 7 CUSTOMER_ID, PRODUCT_NAME,counts,rank() over(partition by customer_id order by counts desc ) as rank_no
from product_id_count)

select customer_id,product_name from ranks
where rank_no=1

---------------------------------------------------------------------------------

-- Q(6) Which item was purchased first by the customer after they became a member?

with after_member_purchase as
(select top 100 percent s.*,m.product_name,c.join_date, rank() over(partition by  c.customer_id order by order_date) as ranks
from sales s
left join members c on c.customer_id=s.customer_id join menu m on m.product_id=s.product_id
where s.order_date>=c.join_date)

select  customer_id,join_date as became_member,order_date as first_purchased,product_name as item
from after_member_purchase
where ranks=1

------------------------------------- --------------------------------------------

-- Q(7) Which item was purchased just before the customer became a member?
with just_before_join as 
(select top 100 percent s.*,m.product_name,c.join_date, LAST_VALUE(product_name) over(partition by s.customer_id order by order_date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as item_purchased
from sales s
left join members c on c.customer_id=s.customer_id join menu m on m.product_id=s.product_id
where s.order_date<c.join_date)

select customer_id,item_purchased,join_date,max(order_date) as just_before_join_order_date
from just_before_join
group by item_purchased,customer_id,join_date

----------------------------------------------------------------------------------

--Q(8) What is the total items and amount spent for each member before they became a member?

select s.customer_id,COUNT(s.product_id) as Total_items,sum(m.price) as total_amount
from sales s
left join menu m on s.product_id=m.product_id 
join members c on s.customer_id=c.customer_id
where order_date<join_date
group by s.customer_id

----------------------------------------------------------------------------------

--Q(9) If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

with point as
(select * ,case 
        when product_name='sushi' then price*20 
		else price*10 END as points
from menu)

select s.customer_id, sum(p.points) as total_points
from sales s 
join point p on s.product_id=p.product_id
group by s.customer_id

-------------------------------------------------------------------------------------

-- Q(10) In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi 
--       -how many points do customer A and B have at the end of January?

with point as
(select *, price*20 as points from menu )

select s.customer_id,sum(points) as total_points
from sales s
join members m on s.customer_id=m.customer_id join point p on p.product_id=s.product_id 
where order_date>=join_date and order_date<'2021-02-01'
group by s.customer_id

-------------------------------------------------------------------------------------
--Recreate the following table for danny

select s.customer_id,order_date,product_name,price,(Case
                        when s.customer_id not IN (SELECT customer_id from members)then 'N'
						WHEN EXISTS (SELECT 1 FROM members WHERE customer_id = s.customer_id AND join_date <= s.order_date) THEN 'Y'
		               else 'N'
					  END ) as member
from sales s
join menu m on s.product_id=m.product_id 

-------------------------------------------------------------------------------------

/*
                       Rank All The Things

Danny also requires further information about the ranking of customer products,
but he purposely does not need the ranking for non-member purchases so he expects 
null ranking values for the records when customers are not yet part of the loyalty program.


*/
with rankingS as
(select s.customer_id,order_date,product_name,price,(Case
                        when s.customer_id not IN (SELECT customer_id from members)then 'N'
						WHEN EXISTS (SELECT 1 FROM members WHERE customer_id = s.customer_id AND join_date <= s.order_date) THEN 'Y'
		               else 'N'
					  END ) as member
from sales s
join menu m on s.product_id=m.product_id )

select *,(Case 
			WHEN MEMBER='N' THEN null
			ELSE RANK() OVER (PARTITION BY customer_id,member ORDER BY order_date )
			end ) as ranking
from rankingS
----------------------------------------------------------------------------------------
