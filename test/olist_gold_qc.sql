/*
=======================================================================================================
 Data Quality check for gold layer
=======================================================================================================

Purpose:
	- Check the data integrationa and relationship integrity.
	- Check the data quaity for the view


Highlight:
	- Checking duplicate for key columns and duplicates for overall columns
	- no. of. nulls in each columns and their %
	- Inconsistent data and format issue for dimensions
	- Date range and date consistency issue
	- Checking if every column has correct data types.
	

=======================================================================================================
*/

--=========================================================================
-- Data quality and relationship check for the gold.dim_o_customers view
--=========================================================================

select * from silver.olist_customers; --99441 rows

select * from gold.dim_o_customers; --99441 rows


--=========================================================================
-- Data quality and relationship check for the gold.dim_o_products view
--=========================================================================

select * from silver.olist_products;--Total rows: 32951

select * from gold.dim_o_products; --32951 rows

--=========================================================================
-- Data quality and relationship check for the gold.dim_o_sellers view
--=========================================================================

select * from silver.olist_sellers;--Total rows: 3095

select * from gold.dim_o_sellers;-- 3095 rows

--=========================================================================
-- Data quality and relationship check for the gold.dim_o_reviews view
--=========================================================================

select * from silver.olist_order_reviews;--Total rows: 99224

select * from gold.dim_o_reviews --98673 since we only took the latest review for an order


--=========================================================================
-- Data quality and relationship check for the gold.fact_o_orders view
--=========================================================================

select * from silver.olist_orders;--99441

select * from silver.olist_order_items_agg; --98666

select * from silver.olist_payments_agg;--99440

--------------------------------------------------------------------------------
select * from gold.fact_o_orders;--Total rows: 99441


--distinct category value check

select distinct order_status from gold.fact_o_orders;

select distinct primary_payment_type from gold.fact_o_orders;


select *
from (select
		right(o.order_id, 10) order_number,
		o.order_id,
		customer_key,
		order_status,
		order_purchase_timestamp,
		order_approved_at,
		order_delivered_carrier_date,
		order_delivered_customer_date,
		order_estimated_delivery_date,
		shipping_limit_date,
		num_items,
		num_distinct_products,
		num_distinct_sellers,
		total_item_price,
		total_freight_value,
		total_order_value,
		payment_sequential_cn,
		num_payment_type,
		payment_installments,
		total_payment_value,
		primary_payment_type,
		has_invalid_timestamp_sequence

		
from silver.olist_orders o left join silver.olist_order_items_agg i on o.order_id=i.order_id
						   left join silver.olist_payments_agg py on o.order_id=py.order_id
						   left join dim_o_customers c on o.customer_id = c.customer_id)
where total_order_value != total_payment_value
--where order_number is null or order_number = '6121a158'
group by order_number
having count(order_number)>1
--------------------------------------------------------------------------------
select order_id, total_payment_value, total_order_value, abs(total_payment_value - total_order_value)
from (select
		right(o.order_id, 10) order_number,
		o.order_id,
		customer_key,
		order_status,
		order_purchase_timestamp,
		order_approved_at,
		order_delivered_carrier_date,
		order_delivered_customer_date,
		order_estimated_delivery_date,
		shipping_limit_date,
		num_items,
		num_distinct_products,
		num_distinct_sellers,
		total_item_price,
		total_freight_value,
		total_order_value,
		payment_sequential_cn,
		num_payment_type,
		payment_installments,
		total_payment_value,
		primary_payment_type,
		has_invalid_timestamp_sequence

		
from silver.olist_orders o left join silver.olist_order_items_agg i on o.order_id=i.order_id
						   left join silver.olist_payments_agg py on o.order_id=py.order_id
						   left join dim_o_customers c on o.customer_id = c.customer_id)
where total_order_value != total_payment_value
order by  abs(total_payment_value - total_order_value) desc

--------------------------------------------------------------------------------

select * from gold.fact_o_orders;--99441 -- no fan out risk after joining the dim_o_reviews view

--------------------------------------------------------------------------------

--to check the count and percentage of the delivery_bucket_status
select delivery_bucket_status, count(*) , round(count(*)::numeric / sum(count(*)) over()*100,1) perct_bucket_values
from gold.fact_o_orders
group by delivery_bucket_status;

--------------------------------------------------------------------------------

--checking the missing item based on the null value

SELECT COUNT(*) FROM gold.fact_o_orders WHERE delivery_bucket_status IS NULL;
SELECT order_status, COUNT(*) FROM gold.fact_o_orders WHERE delivery_bucket_status IS NULL GROUP BY order_status;



-------------------------------------------------------------------------

--found out some order dont have delivered_customer_date is null, but the order status shows delivered. so checking what details does it contains

SELECT order_id, order_status, order_delivered_customer_date, order_approved_at, order_delivered_carrier_date
FROM gold.fact_o_orders
WHERE order_status = 'Delivered' AND delivery_bucket_status IS NULL;

--=========================================================================
-- Data quality and relationship check for the gold.fact_order_items view
--=========================================================================


--fan out risk check
select * from silver.olist_order_items;--Total rows: 112650

select * from gold.fact_order_items;--Total rows: 112650




--=========================================================================
-- Data quality and relationship check for the gold.dim_o_dates view
--=========================================================================

select * from gold.dim_o_dates;--Total rows: 800

select min(full_date) , max(full_date) from gold.dim_o_dates; --min: "2016-09-04",	max: "2018-11-12"






