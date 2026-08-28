/*
=======================================================================================================
 Gold Layer: Views & Model 
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

show search_path;

set search_path to gold, bronze;

alter role postgres set search_path to gold, bronze;

--========================================
-- gold.dim_o_customers view
--========================================

drop view if exists gold.dim_o_customers;

create or replace view gold.dim_o_customers as
	select 
			row_number() over(order by customer_id) customer_key,
			customer_id,
			customer_unique_id,
			customer_zip_code_prefix,
			customer_city,
			customer_state
			
	from silver.olist_customers



--========================================
-- gold.dim_o_products view
--========================================


drop view if exists gold.dim_o_products;

create or replace view gold.dim_o_products as
select 
		row_number() over(order by product_id) product_key,
		product_id,
		product_category_name product_category_name_eng,
		product_weight_g,
		product_length_cm,
		product_height_cm,
		product_width_cm

from silver.olist_products

--========================================
-- gold.dim_o_sellers view
--========================================


drop view if exists gold.dim_o_sellers;

create or replace view gold.dim_o_sellers as
select
		row_number() over(order by seller_id) seller_key,
		seller_id,
		seller_zip_code_prefix,
		seller_city,
		seller_state
		
from silver.olist_sellers

--==================================================================
-- gold.dim_o_reviews view -- only one review score for an order
--==================================================================


drop view if exists gold.dim_o_reviews;

create or replace view gold.dim_o_reviews as
		with ranked_reviews as
				(
					select *, row_number() over(partition by order_id order by review_creation_date desc) ranks
					from silver.olist_order_reviews
				)
		
		select review_id, order_id, review_score, ranks
		from ranked_reviews
		where ranks = 1

--select * from gold.dim_o_reviews;

--========================================
-- gold.fact_o_orders view
--========================================

drop view if exists gold.fact_o_orders;

create or replace view gold.fact_o_orders as
				
			with t1 as 
				(
						select
								row_number() over(order by o.order_id) order_key,
								o.order_id,
								customer_key,
								c.customer_unique_id,
								order_status,
								num_items,
								num_distinct_products,
								total_item_price,
								total_freight_value,
								total_order_value,
								
								order_purchase_timestamp,
								order_approved_at,
								order_delivered_carrier_date,
								order_delivered_customer_date,
								order_estimated_delivery_date,
								
								num_distinct_sellers,
								num_payment_type,
								payment_installments,
								primary_payment_type,
								
								review_score,
								
								round(extract ( epoch from (order_delivered_customer_date - order_estimated_delivery_date))/86400.0,2) as delivery_delay_days,
						
								case when order_delivered_customer_date is null then null
									 when order_delivered_customer_date<=order_estimated_delivery_date then 'On time'
									 else 'Late'
								end delivery_status,
								
								o.has_invalid_timestamp_sequence
						
								
						from silver.olist_orders o left join silver.olist_order_items_agg i on o.order_id=i.order_id
												   left join silver.olist_payments_agg py on o.order_id=py.order_id
												   left join gold.dim_o_customers c on o.customer_id = c.customer_id
												   left join gold.dim_o_reviews r on o.order_id = r.order_id
				) ,
										   
----------------------------------------------
			t2 as -- for finding about the percentile for delivery_delay_days<0 at 10 percentile and delivery_delay_days>0 at 90 percentile.
				(
						 select 
							 
								 (select percentile_cont(0.10) within group (order by delivery_delay_days)  from t1 where delivery_delay_days<0) as at_10p,  -- (-21.96)
								  
								  percentile_cont(0.90) within group (order by delivery_delay_days) as at_90p --21.56
					
						 from t1
						 where delivery_delay_days>0
				 )
-----------------------------------------------
			
			select 
						order_key,
						order_id,
						customer_key,
						customer_unique_id,
						order_status,
						num_items,
						num_distinct_products,
						total_item_price,
						total_freight_value,
						total_order_value,
						
						order_purchase_timestamp,
						order_approved_at,
						order_delivered_carrier_date,
						order_delivered_customer_date,
						order_estimated_delivery_date,
						
						num_distinct_sellers,
						num_payment_type,
						payment_installments,
						primary_payment_type,
						
						review_score,
						
						delivery_delay_days,
				
						delivery_status,
			
						case when order_delivered_customer_date is null then null
							 when delivery_delay_days<= (select at_10p from t2)  then 'Early'
							 when delivery_delay_days<=0 then 'On Time'
							 when delivery_delay_days<= (select at_90p from t2) then 'Late'
							 else 'Very Late'
						end delivery_bucket_status,
						
						has_invalid_timestamp_sequence	
						
			from t1 
							
--select * from gold.fact_o_orders;


--=======================================================================================================
-- Creating gold.fact_order_items
--=======================================================================================================

select * from silver.olist_order_items;

select * from gold.fact_o_orders;

select * from gold.dim_o_sellers;

select * from gold.dim_o_products;

---creatinge fact_order_items view
drop view if exists gold.fact_order_items;

create or replace view gold.fact_order_items as
		select
				row_number() over(order by i.order_id, i.order_item_id)  order_item_key,
				i.order_id,
				i.order_item_id,
				o.order_key,
				o.customer_key,
				p.product_key,
				s.seller_key,
				i.price,
				i.freight_value,
				i.shipping_limit_date
				
		from silver.olist_order_items i join gold.fact_o_orders o on i.order_id = o.order_id
										join gold.dim_o_sellers s on i.seller_id = s.seller_id
										join gold.dim_o_products p on i.product_id = p.product_id


--==================================================================
-- gold.dim_o_dates view
--==================================================================

drop view if exists gold.dim_o_dates;

create or replace view gold.dim_o_dates as
		with date_t1 as
				(select
						least(min(order_purchase_timestamp), min(order_approved_at), min(order_delivered_carrier_date),
										min(order_delivered_customer_date), min(order_estimated_delivery_date)) min_dt,
						greatest(max(order_purchase_timestamp), max(order_approved_at), max(order_delivered_carrier_date), 
										max(order_delivered_customer_date), max(order_estimated_delivery_date)) max_dt
				from fact_o_orders)
		
		select
				to_char(dt, 'yyyymmdd')::int as date_key,
				dt::date as full_date,
				extract(year from dt)::int as year,
				extract(quarter from dt)::int as quarter,
				extract(month from dt)::int as month,
				trim(to_char(dt,'Month')) as month_name,
				extract(day from dt)::int as day,
				extract(isodow from dt)::int as day_of_week,
				trim(to_char(dt, 'Day')) as  week_day,
				case when extract(isodow from dt) in (6,7) then true else false end as is_weekend,
				extract(week from dt)::int as week_num
				
		from generate_series((select min_dt from date_t1)::date, 
							 (select max_dt from date_t1)::date, 
							 interval '1 day') dt;


--=======================================================================================================
















