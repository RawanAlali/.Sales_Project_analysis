/*
===============================================================================
Product Report
===============================================================================
Purpose:
    - This report consolidates key product metrics and behaviors.

Highlights:
    1. Gathers essential fields such as product name, category, subcategory, and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    3. Aggregates product-level metrics:
       - total orders
       - total sales
       - total quantity sold
       - total customers (unique)
       - lifespan (in months)
    4. Calculates valuable KPIs:
       - recency (months since last sale)
       - average order revenue (AOR)
       - average monthly revenue
===============================================================================
*/
-- =============================================================================
create view report_products as 
with base_querry as (
select 
order_number,
order_date,
s.product_key,
product_id,
product_name,
category,
subcategory,
product_line,
cost,
sales_amount,
quantity,
customer_key
from fact_sales s
left join products p
on s.product_key=p.product_key
)
, main_cte2 as
(
select
product_key,
product_name,
category,
subcategory,
product_line,
sum(sales_amount) total_sale,
sum(quantity) total_quantity,
count(distinct order_number) total_order,
count(distinct customer_key) number_of_customer,
DATEDIFF(MONTH,min(order_date),max(order_date)) life_span,
DATEDIFF(MONTH,max(order_date),GETDATE()) recency
from base_querry
group by
product_key,
product_name,
category,
subcategory,
product_line
)
select *,
case
when total_sale >5000 then'High-Performer'
when total_sale >=1000 then'Mid-Range'
else 'Low-Performer'
end product_segment,
case
when total_order=0 then 0 else total_sale/total_order
end average_order_revenue,
case
when life_span=0 then 0 else total_sale/life_span
end average_monthly_revenue
from main_cte2