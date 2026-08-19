	/*
===============================================================================
Customer Report
===============================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights:
    1. Gathers essential fields such as names, ages, and transaction details.
	2. Segments customers into categories (VIP, Regular, New) and age groups.
    3. Aggregates customer-level metrics:
	   - total orders
	   - total sales
	   - total quantity purchased
	   - total products
	   - lifespan (in months)
    4. Calculates valuable KPIs:
	    - recency (months since last order)
		- average order value
		- average monthly spend
===============================================================================
*/

-- =============================================================================
-- Create Report: gold.report_customers
-- =============================================================================
;
CREATE VIEW  report_customers AS
with main_cte as (
select 
s.order_number,
c.customer_key,
customer_number,
CONCAT(c.first_name,' ',c.last_name) total_name,
order_date,
sales_amount,
product_key,
quantity,
price,
birthdate,
datediff(year,birthdate,getdate()) age
from fact_sales s
left join  customers c
on s.customer_key=c.customer_key
where order_date is not null
)
, cte_2 as (

select 
customer_key,
customer_number,
total_name,
 age,
datediff(month,min(order_date),max(order_date)) life_span,
sum(sales_amount) total_sale,
count(distinct product_key)total_product,
sum(quantity)total_quantity,
count( order_number) total_order,
datediff(month,max(order_date),getdate()) recency
from main_cte
group by 
customer_key,
customer_number,
total_name,
age
) 
select *,

case
when age between 20 and 29 then ' between 20 and 29'
when age between 30 and 39 then ' between 30 and 39'
when age between 40 and 49 then ' between 40 and 49'
when age between 50 and 59 then ' between 50 and 59'
else 'older 60'
end age_statue,
case
when  total_sale>5000 and life_span>=12 then 'VIP'
when  total_sale<=5000 and life_span>=12 then 'Regular'
else 'New'
end customer_statement,
case 
when total_order=0 then  0 else total_sale/total_order
end average_order_value,
case 
when life_span=0 then total_sale else total_sale/life_span
end average_monthly_spend
from cte_2


