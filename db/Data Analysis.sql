--Change Over Time Analysis
-- Analyse sales performance over time

select order_date,
sum(sales_amount) as totla_sale
from fact_sales
where order_date is not null
group by order_date
order by order_date

-- Analyse sales performance over years

select year(order_date) as year_order_date ,
sum(sales_amount) as totla_sale,
lag(sum(sales_amount))over(order by  year(order_date)) as previos_year_sale,
case 
when (sum(sales_amount)-lag(sum(sales_amount))over(order by  year(order_date)))>0 then 'increase'
when (sum(sales_amount)-lag(sum(sales_amount))over(order by  year(order_date)))<0 then 'deacrease'
else 'nochange'
end yearly_sale_state
from fact_sales
where order_date is not null
group by  year(order_date)
order by  year_order_date

-- Analyse sales performance over monthes

select 
datetrunc(month,order_date) as month_order_date ,
sum(sales_amount) as total_sale,
count(distinct customer_key) as number_customer,
sum(quantity) as total_quantity,
lag(sum(sales_amount))over( order by datetrunc(month,order_date)) previous_month_sale,
lag(count(distinct customer_key))over( order by datetrunc(month,order_date)) previous_number_customer,
case 
when (sum(sales_amount)-lag(sum(sales_amount))over( order by datetrunc(month,order_date)))>0 then 'increase'
when (sum(sales_amount)-lag(sum(sales_amount))over( order by datetrunc(month,order_date)))<0 then 'deacrease'
else 'nochange'
end monthly_sale_state
from fact_sales
where order_date is not null
group by  datetrunc(month,order_date)
order by month_order_date

-- Analyse cumulative_sales performance over monthes


select 
datetrunc(month,order_date) as month_order_date ,
sum(sales_amount) as total_sale,
sum(sum(sales_amount))over(partition by year(datetrunc(month,order_date)) order by datetrunc(month,order_date)) cumulative_sale_per_month
from fact_sales
where order_date is not null
group by  datetrunc(month,order_date)
order by month_order_date

-- Analyse cumulative_sales performance over years

select 
datetrunc(year,order_date) as year_order_date ,
sum(sales_amount) as total_sale,
sum(sum(sales_amount) )over(order by datetrunc(year,order_date)) year_cumulative_sales,
avg(price) as avg_price,
avg(avg(price))over(order by datetrunc(year,order_date)) year_cumulative_price
from fact_sales
where order_date is not null
group by  datetrunc(year,order_date)
order by year_order_date

--Performance Analysis (Year-over-Year, Month-over-Month)
/* Analyze the yearly performance of products by comparing their sales 
to both the average sales performance of the product and the previous year's sales */
select * from fact_sales
select * from products;

 -- Year-over-Year Analysis

with yearly_product_sale as (
select year(order_date) as year_order_date ,
p.product_name,
sum(sales_amount) year_total_sale,
lag(sum(sales_amount))over(partition by p.product_name order by year(order_date)) previous_year_sale
from fact_sales s
left join products p
on s.product_key=p.product_key
where order_date is not null
group by  year(order_date),
p.product_name
)
select * 
,
case 
when( year_total_sale - previous_year_sale)>0 then'good'
when( year_total_sale - previous_year_sale)<0 then'bad'
else'equal'
end dff_recent_preview_sale,
avg(year_total_sale)over(partition by product_name) avg_sale_perproduct,
 year_total_sale -avg(year_total_sale)over(partition by product_name) diff_avg,
case 
when( year_total_sale -avg(year_total_sale)over(partition by product_name))>0 then'above avg'
when( year_total_sale - avg(year_total_sale)over(partition by product_name))<0 then'below avg'
else'avg'
end dff_recent_avg_sale
from yearly_product_sale;


 -- month-over-month_category sale and customer number Analysis
with category_montly_sale as (
select  
category,
datetrunc(month,order_date) as month_order_date ,
sum(sales_amount) total_sale,
lag(sum(sales_amount))over(partition by category order by datetrunc(month,order_date)) previus_month_sale,
count(distinct customer_key) customer_number,
lag(count(distinct customer_key))over(partition by category order by datetrunc(month,order_date)) previus_customer_number
from fact_sales s
left join products p
on s.product_key=p.product_key
where order_date is not null
group by datetrunc(month,order_date) ,category
)
select * ,
avg(total_sale)over(partition by year(month_order_date),category) avg_year_sale,
case
when customer_number - previus_customer_number>0 then 'increase'
when customer_number- previus_customer_number<0 then 'decrease'
else 'nochange'
end monthly_state_sale,
case
when total_sale-previus_month_sale>0 then 'increase'
when total_sale-previus_month_sale<0 then 'decrease'
else 'nochange'
end customer_number_state,
case
when total_sale-avg(total_sale)over(partition by year(month_order_date),category)>0 then 'good'
when total_sale-avg(total_sale)over(partition by year(month_order_date),category)<0 then 'bad'
else 'nochange'
end diff_avg_sale
from category_montly_sale
order by category,month_order_date

-- Which categories contribute the most to overall sales?
select 
category,
sum(sales_amount) total_sale,
sum(sum(sales_amount))over(order by (select null)) all_sale,
concat(round(sum(sales_amount)/cast (sum(sum(sales_amount))over(order by (select null))as float)*100,2),'%')
from fact_sales s
left join products p
on s.product_key=p.product_key
where order_date is not null
group by category
order by   total_sale desc

/*Segment products into cost ranges and 
count how many products fall into each segment*/
select cost_statue,
count(cost_statue) count_item
from (
select product_name,
cost,
case
when  cost<100 then 'below 100'
when  cost>100  and cost < 500 then 'between 100 and 500'
when  cost>500  and cost < 1000 then 'between 500 and 1000'
when  cost>1000 then 'above 1000'
end cost_statue
from products) as tt
group by cost_statue
order by count_item

/*Group customers into three segments based on their spending behavior:
	- VIP: Customers with at least 12 months of history and spending more than €5,000.
	- Regular: Customers with at least 12 months of history but spending €5,000 or less.
	- New: Customers with a lifespan less than 12 months.
And find the total number of customers by each group
*/

with customer_behavoir as (
select 
C.customer_key,
CONCAT(first_name,last_name) total_name,
SUM(sales_amount) total_sales,
DATEDIFF(MONTH,min(order_date),max(order_date)) life_span
from fact_sales s
left join  customers c
on s.product_key=c.customer_key
group by C.customer_key,
CONCAT(first_name,last_name)
), customer_statue as(
select * ,
case
when  total_sales>5000 and life_span>=12 then 'VIP'
when  total_sales<=5000 and life_span>=12 then 'Regular'
else 'New'
end customer_statement
from customer_behavoir)
select 
customer_statement,
count(customer_statement) number_statement
from  customer_statue 
group by 
customer_statement;


--second method
with customer_behavoir as (
select 
C.customer_key,
CONCAT(first_name,last_name) total_name,
SUM(sales_amount) total_sales,
DATEDIFF(MONTH,min(order_date),max(order_date)) life_span,
case
when  SUM(sales_amount)>5000 and DATEDIFF(MONTH,min(order_date),max(order_date))>=12 then 'VIP'
when SUM(sales_amount)<=5000 and DATEDIFF(MONTH,min(order_date),max(order_date))>=12 then 'Regular'
else 'New'
end customer_statement
from fact_sales s
left join  customers c
on s.product_key=c.customer_key
group by C.customer_key,
CONCAT(first_name,last_name)
)
select 
customer_statement,
count(customer_statement) number_statement
from customer_behavoir
group by customer_statement