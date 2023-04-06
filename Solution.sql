--Ques1. What is the total amount each customer spent at the restaurant?

select customer_id, sum(price) as total_amount_spent_by_each_customer
from sales s
join menu m 
on s.product_id=m.product_id
group by customer_id



--Ques2.How many days has each customer visited the restaurant?

select customer_id,count(distinct order_date) as no_of_days
from sales s
join menu m 
on s.product_id=m.product_id
group by customer_id




--Ques3. What was the first item from the menu purchased by each customer?

with cte as (
select s.customer_id as customer_id,s.product_id,product_name,
row_number() over(partition by customer_id order by order_date asc) first_order
from sales s
join menu m 
on s.product_id=m.product_id)
select customer_id,product_name from cte
where first_order=1




--Ques4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select top 1 count(*) no_of_times_ordered,product_name
from sales s
join menu m 
on s.product_id=m.product_id
group by product_name



--Ques5. Which item was the most popular for each customer?

with cte as (
select customer_id,product_name ,count(*) countt,
ROW_NUMBER() over (partition by customer_id order by count(*) desc) rn
from menu m
join sales s 
on m.product_id=s.product_id
group by customer_id,m.product_name
)
select customer_id,product_name
from cte where rn=1




--Ques6. Which item was purchased first by the customer after they became a member?

select product_name from
members join sales 
on members.customer_id=sales.customer_id
join menu on menu.product_id=sales.product_id
where order_date in (select min(join_date) from members)




--Ques7. Which item was purchased just before the customer became a member?

with cte as
(select s.customer_id as customer_id, product_id, order_date,
	rank() over(partition by s.customer_id order by order_date desc) as rn
from sales s 
join members m on s.customer_id=m.customer_id
where order_date<join_date)

select cte.customer_id, cte.product_id, product_name, order_date
from cte
join menu m on cte.product_id=m.product_id
where rn=1
order by cte.customer_id;




--Ques8. What is the total items and amount spent for each member before they became a member?

select s.customer_id,sum(price) as total_amount,count(*) as total_items
from menu m join sales s on m.product_id=s.product_id
where order_date<(select min(join_date) from members) and 
s.customer_id in (select members.customer_id from members)
group by s.customer_id
order by s.customer_id




--Ques9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

select customer_id,
sum(case when product_name='sushi' then price*20 else price*10 end) points
from sales s
join menu m 
on s.product_id=m.product_id
group by customer_id




--Ques10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

select s.customer_id,sum(price)*20 as points
from sales s
join menu m on s.product_id=m.product_id
join members on
members.customer_id=s.customer_id
where order_date between join_date and DATEADD(day,7,join_date)
group by s.customer_id




--Bonus Question

with cte as (
select sales.customer_id as customer_id,order_date,product_name,price,
case when sales.customer_id in (select members.customer_id from members) 
and order_date>=(select min(join_date) from members)
then 'Y' else 'N' end member,
ROW_NUMBER() over (partition by sales.customer_id order by order_date) rn
from sales
left join menu on sales.product_id=menu.product_id
left join members on sales.customer_id=members.customer_id
)
select customer_id,order_date,product_name,price,member,
case when member='Y' then rank() over (partition by customer_id,member order by order_date) else null end ranking
from cte
order by customer_id,order_date,product_name
