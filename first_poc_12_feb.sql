--first POC date 12 feb 2022 



----------------------------------create table query for POC------------------------------------------------


create table members (
customer_id varchar2(1) primary key,
join_date TIMESTAMP
);

create table menu (
product_id integer primary key,
product_name varchar2(5),
price integer
);
 
create table sales 
(
customer_id varchar2(1) REFERENCES members(customer_id),
order_date date,
product_id integer REFERENCES menu(product_id)
);


----------------------------------insert record into the table -----------------------------------------------


--insert into menu
insert into menu values (1,'sushi',10);
insert into menu values (2,'curry',15);
insert into menu values (3,'ramen',12);


--insert into members
insert into members values ('A',to_date('2021-01-07','YYYY-MM-DD'));
insert into members values ('B',to_date('2021-01-09','YYYY-MM-DD'));
insert into members values ('C',to_date('2021-01-07','YYYY-MM-DD'));


--insert into sales

insert all into sales values('A',to_date('2021-01-01','YYYY-MM-DD'),1)
into sales values('A',to_date('2021-01-01','YYYY-MM-DD'),2)
into sales values('A',to_date('2021-01-07','YYYY-MM-DD'),2)
into sales values('A',to_date('2021-01-10','YYYY-MM-DD'),3)
into sales values('A',to_date('2021-01-11','YYYY-MM-DD'),3)
into sales values('A',to_date('2021-01-11','YYYY-MM-DD'),3)
into sales values('B',to_date('2021-01-01','YYYY-MM-DD'),2)
into sales values('B',to_date('2021-01-02','YYYY-MM-DD'),2)
into sales values('B',to_date('2021-01-04','YYYY-MM-DD'),1)
into sales values('B',to_date('2021-01-11','YYYY-MM-DD'),1)
into sales values('B',to_date('2021-01-16','YYYY-MM-DD'),3)
into sales values('B',to_date('2021-02-01','YYYY-MM-DD'),3)
into sales values('C',to_date('2021-01-01','YYYY-MM-DD'),3)
into sales values('C',to_date('2021-01-01','YYYY-MM-DD'),3)
into sales values('C',to_date('2021-01-07','YYYY-MM-DD'),3)
select * from dual;



-----------------------------Case Study Questions:-------------------------
--1) What is the total amount each customer spent at the restaurant? 

--ans : 
select 
customer_id,
sum(PRICE)
from
(select s.customer_id,
s.product_id,
m.price
from sales s
join 
menu m
on s.product_id=m.product_id
)
group by customer_id;

--2) How many days has each customer visited the restaurant?


--Ans 2

select 
customer_id,
count(distinct order_date) as days
from
(
select
customer_id,
order_date 
from
sales
)
group by customer_id
order by customer_id ;

--3) What was the first item from the menu purchased by each customer? 
--Ans 3
select 
customer_id ,
order_date,
product_id,
product_name,
var_rank
from
(
select distinct s.customer_id ,m.product_id,
s.order_date,
m.product_name,
rank() over(PARTITION by customer_id order by s.order_date ) as var_rank
from 
sales s
join
menu m
on s.product_id=m.product_id
)
where var_rank=1;

--4) What is the most purchased item on the menu and how many times was it purchased by all
--customers? 

select
*
from
(
select 
distinct product_id as product,
count(customer_id) over( partition by product_id ) as var_count
from 
sales
order by product desc
)
where rownum=1
;


--5) Which item was the most popular for each customer? 

select customer_id,product_id,var_count
from
(select customer_id,product_id,var_count,
rank() over( partition by customer_id order by  var_count desc) as var_rank
from
(select customer_id, product_id,count(product_id) as var_count
from 
sales
group by customer_id,product_id
order by customer_id,var_count desc
)
)
where var_rank=1;

--6) Which item was purchased first by the customer after they became a member?

select customer_id,
product_id,
var_rank
from 
(
select 
s.customer_id,
s.product_id,
rank() over(partition by s.customer_id order by s.order_date) as var_rank
from 
sales s
join
members m
on s.customer_id=m.customer_id
where s.order_date>=m.join_date
)
where var_rank=1
;

--7) Which item was purchased just before the customer became a member? 


select customer_id,
product_id,
var_rank
from 
(
select 
s.customer_id,
s.product_id,
s.order_date,
m.join_date,
rank() over(partition by s.customer_id order by s.order_date desc) as var_rank
from 
sales s
join
members m
on s.customer_id=m.customer_id
where s.order_date<=m.join_date
)
where var_rank=1
;

--8) What is the total items and amount spent for each member before they became a member? 


select distinct customer_id ,total_amount_spent from
(select 
var2_join.customer_id,
var2_join.total_amount_spent,
RANK() OVER(partition by var2_join.customer_id order by var2_join.price) as rowrank
from
(
select var_join.customer_id,
var_join.total_item,
mm.price,
sum(mm.price) over( partition by customer_id) as total_amount_spent
from 
(
select s.customer_id,
s.product_id,
count(*) over(partition by s.customer_id)as total_item
from sales s
join members m
on s.customer_id=m.customer_id
where s.order_date<m.join_date
) var_join left join menu mm 
on var_join.product_id=mm.PRODUCT_ID
) var2_join) where rowrank=1 ;


--9)9) If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points 
--would each customer have?

select customer_id,sum(points) total_points from(
select sales.customer_id customer_id,sales.product_id product_id,menu.product_name product_name,menu.price,
case menu.product_name
when 'sushi' then menu.price*2*10
else menu.price*10
end points
from sales inner join members on sales.customer_id=members.customer_id 
inner join menu on sales.product_id=menu.product_id) group by customer_id;


--10) In the first week after a customer joins the program (including their join date) they earn 
--2x points on all items, not just sushi - how many points do customer A and B have at the 
--end of January?


select customer_id,sum(points) total_points from (
 select sales.customer_id customer_id,sales.product_id product_id,menu.product_name product_name,menu.price,
sales.order_date-to_date(to_char(members.join_date,'dd-mm-yy')) no_of_days,sales.order_date order_date,
case
when 
(sales.order_date-to_date(to_char(members.join_date,'dd-mm-yy')) >0) and 
(sales.order_date-to_date(to_char(members.join_date,'dd-mm-yy'))<7) then menu.price*2*10
else(  case when product_name ='sushi' then price*10*2 else price*10 end )
end points
from sales inner join members on sales.customer_id=members.customer_id 
inner join menu on sales.product_id=menu.product_id ) where order_date < to_date('01-02-21','dd-mm-yy') group by customer_id ;







































