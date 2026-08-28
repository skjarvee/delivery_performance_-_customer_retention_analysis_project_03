/*
=======================================================================================================
 Initial Exploritory Data Analysis for olist datasets
=======================================================================================================

Purpose:
	1. Exploring the dataset and find the data quality issue in each table and documenting the issue.

Highlight:
	- Checking duplicate for key columns and duplicates for overall columns
	- no. of. nulls in each columns and their %
	- Inconsistent data and format issue for dimensions
	- Date range and date consistency issue
	- Checking if every column has correct data types.
	

=======================================================================================================
*/

show search_path; --checking the selected schema

-------------------------------------------------
--initial EDA on bronze.olist_customers
-------------------------------------------------

select * from bronze.olist_customers;

--Duplicate and null check on key columns
select customer_id
from bronze.olist_customers
group by customer_id
having count(*) >1;

--full rows uniqueness check
select *
from (select *, count(*) over(partition by customer_id, customer_unique_id,customer_zip_code_prefix,customer_city,customer_state) cn
from bronze.olist_customers) t1
where cn>1;

-- total rows and nulls count and nulls %, also checking negative values

select 
		count(*) total_rows,
		
		count(*) filter( where customer_id is null) nulls_customer_id,
		round(count(*) filter( where customer_id is null)::numeric/count(*)*100,2) nulls_customer_id_per,
		
		count(*) filter( where customer_unique_id is null) nulls_customer_id,
		round(count(*) filter( where customer_unique_id is null)::numeric/count(*)*100,2) nulls_customer_unique_id_per,
		
		count(*) filter( where customer_zip_code_prefix is null or customer_zip_code_prefix<=0) nulls_customer_zipcode,
		round(count(*) filter( where customer_zip_code_prefix is null or customer_zip_code_prefix<=0)::numeric/count(*)*100,2) nulls_customer_zipcode_per,
		
		count(*) filter( where customer_city is null) nulls_customer_city,
		round(count(*) filter( where customer_city is null)::numeric/count(*)*100,2) nulls_customer_city_per,
		
		count(*) filter( where customer_state is null) nulls_customer_state,
		round(count(*) filter( where customer_state is null)::numeric/count(*)*100,2) nulls_customer_state_per
from bronze.olist_customers

--fan-out risk(if we join this table to other table, does the rows count increase on main table(orders))
select count(*) from bronze.olist_orders; --99441 rows

select count(*)
from bronze.olist_orders o left join bronze.olist_customers c using(customer_id)--99441 rows

--checking unwanted space in id columns
select *
from bronze.olist_customers
where customer_state != trim(customer_state)

--unique dimensions check
select distinct customer_state
from bronze.olist_customers

--checking data consistency and format
select customer_zip_code_prefix from bronze.olist_customers
where customer_zip_code_prefix <=0;

--checking uniqueness of column: customer_unique_id
select customer_unique_id
from bronze.olist_customers
group by customer_unique_id
having count(*)>1
--=======================================================================================================
-------------------------------------------------
--initial EDA on bronze.olist_geolocation
-------------------------------------------------

select * from bronze.olist_geolocation;

--Checking for duplicates and null in key column

select geolocation_zip_code_prefix
from bronze.olist_geolocation
--where geolocation_zip_code_prefix is null or geolocation_zip_code_prefix<=0
group by geolocation_zip_code_prefix
having count(*)>1

--full-rows duplicate check
select *
from (select *, count(*) over(partition by geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state) cn
		from bronze.olist_geolocation) t1
where cn>1

--fan_out risk check

select count(*) from bronze.olist_customers--99441

select * from bronze.olist_sellers--3095

select * from bronze.olist_customers c left join bronze.olist_geolocation l on c.customer_zip_code_prefix = l.geolocation_zip_code_prefix --15083733

--null count and percentage

select 
		count(*) total_rows,
		
		count(*) filter( where geolocation_zip_code_prefix is null or geolocation_zip_code_prefix<=0) nulls_zipcode,
		round(count(*) filter( where geolocation_zip_code_prefix is null or geolocation_zip_code_prefix<=0)::numeric/count(*)*100,2) nulls_zipcode_per,
		
		count(*) filter( where geolocation_lat is null) nulls_geolocation_lat,
		round(count(*) filter( where geolocation_lat is null)::numeric/count(*)*100,2) nulls_geolocation_lat_per,
		
		count(*) filter( where geolocation_lng is null) nulls_geolocation_lng,
		round(count(*) filter( where geolocation_lng is null)::numeric/count(*)*100,2) nulls_geolocation_lng_per,
		
		count(*) filter( where geolocation_city is null) nulls_geolocation_city,
		round(count(*) filter( where geolocation_city is null)::numeric/count(*)*100,2) nulls_geolocation_city_per,
		
		count(*) filter( where geolocation_state is null) nulls_geolocation_state,
		round(count(*) filter( where geolocation_state is null)::numeric/count(*)*100,2) nulls_geolocation_state_per
from bronze.olist_geolocation

--Data consistency and format check

select min(geolocation_lat), max(geolocation_lat), min(geolocation_lng), max(geolocation_lng) from bronze.olist_geolocation
--where geolocation_lat=0

select *
from bronze.olist_geolocation
where geolocation_state != trim(geolocation_state)

--distinct value check

select distinct geolocation_city
from bronze.olist_geolocation

--=======================================================================================================

-------------------------------------------------
--initial EDA on bronze.olist_order_items
-------------------------------------------------

select * from bronze.olist_order_items;--112650

--duplicate and null check on key columns
select *
from (select *, count(*) over(partition by order_id) cn
from bronze.olist_order_items) t1
where cn>1

--ful row cuplicate check

select *
from (select *, count(*) over(partition by order_id,order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value) cn
from bronze.olist_order_items) t1
where cn>1

--fan out risk check
/*
we're checking this tables uniquesness so don't have to check the fan out risk for these table since we also join with them.
These table have 1:many relation with order_items, just checking the uniqueness will prove the its not risky.
*/
select * --no duplicates
from (select *, count(*) over(partition by product_id) cn
from bronze.olist_products) t1
where cn>1

select * --no duplicates
from (select *, count(*) over(partition by seller_id) cn
from bronze.olist_sellers) t1
where cn>1

select count(*) from bronze.olist_orders o--99441

select count(*)--112650
from bronze.olist_orders o join bronze.olist_order_items i using(order_id)

select o.order_id, i.order_id, i.product_id --some order are not present in the order_items
from bronze.olist_orders o left join bronze.olist_order_items i using(order_id)
where i.order_id is null


--Nulls check
select 
		count(*) total_rows,
		
		count(*) filter( where order_id is null) nulls_zipcode,
		round(count(*) filter( where order_id is null)::numeric/count(*)*100,2) nulls_order_id_per,
		
		count(*) filter( where order_item_id is null) nulls_item_id,
		round(count(*) filter( where order_item_id is null)::numeric/count(*)*100,2) nulls_item_id_per,
		
		count(*) filter( where product_id is null) nulls_product_id,
		round(count(*) filter( where product_id is null)::numeric/count(*)*100,2) nulls_product_id_per,
		
		count(*) filter( where seller_id is null) nulls_seller_id,
		round(count(*) filter( where seller_id is null)::numeric/count(*)*100,2) nulls_seller_id_per,
		
		count(*) filter( where shipping_limit_date is null) nulls_s_limit_date,
		round(count(*) filter( where shipping_limit_date is null)::numeric/count(*)*100,2) nulls_s_limit_date_per,

		count(*) filter( where price is null) nulls_price,
		round(count(*) filter( where price is null)::numeric/count(*)*100,2) nulls_price_per,

		count(*) filter( where freight_value is null) nulls_freight_value,
		round(count(*) filter( where freight_value is null)::numeric/count(*)*100,2) nulls_freight_value_per
from  bronze.olist_order_items;

--data consistency & format check
select *
from bronze.olist_order_items
where order_item_id<=0

select *
from bronze.olist_order_items
where freight_value<=0

--date range and format check

select min(shipping_limit_date), max(shipping_limit_date)--- min:"2016-09-19 00:15:34"	max:"2020-04-09 22:35:08"
		, age(max(shipping_limit_date),min(shipping_limit_date))--"3 years 6 mons 20 days 22:19:34"
from bronze.olist_order_items

select *
from bronze.olist_orders o left join bronze.olist_order_items i using(order_id)
where order_purchase_timestamp>=shipping_limit_date

--extra space check
select *
from bronze.olist_order_items
where seller_id != trim(seller_id)

--=======================================================================================================

-------------------------------------------------
--initial EDA on bronze.olist_orders
-------------------------------------------------

select * from bronze.olist_orders--99441

--duplicate and null check on key columns
select *
from (select *, count(*) over(partition by order_id) cn
		from bronze.olist_orders) t1
where cn>1 or order_id is null or customer_id is null

--full row duplicate check
select *
from (select *, count(*) over(partition by order_id,customer_id, order_status, order_purchase_timestamp, order_approved_at,
										order_delivered_carrier_date, order_delivered_customer_date, order_estimated_delivery_date) cn
				from bronze.olist_orders) t1
where cn>1

--Nulls count check
select 
		count(*) total_rows,
		
		count(*) filter( where order_id is null) nulls_order_id,
		round(count(*) filter( where order_id is null)::numeric/count(*)*100,2) nulls_order_id_per,
		
		count(*) filter( where customer_id is null) nulls_customer_id,
		round(count(*) filter( where customer_id is null)::numeric/count(*)*100,2) nulls_customer_id_per,
		
		count(*) filter( where order_status is null) nulls_order_status,
		round(count(*) filter( where order_status is null)::numeric/count(*)*100,2) nulls_order_status_per,
		
		count(*) filter( where order_purchase_timestamp is null) nulls_purch_dt,
		round(count(*) filter( where order_purchase_timestamp is null)::numeric/count(*)*100,2) nulls_purch_dt_per,
		
		count(*) filter( where order_approved_at is null) nulls_approv_dt,
		round(count(*) filter( where order_approved_at is null)::numeric/count(*)*100,2) nulls_approv_dt_per,

		count(*) filter( where order_delivered_carrier_date is null) nulls_carrier_dt,
		round(count(*) filter( where order_delivered_carrier_date is null)::numeric/count(*)*100,2) nulls_carrier_dt_per,

		count(*) filter( where order_delivered_customer_date is null) nulls_cus_del_dt,
		round(count(*) filter( where order_delivered_customer_date is null)::numeric/count(*)*100,2) nulls_cus_del_dt_per,

		count(*) filter( where order_estimated_delivery_date is null) nulls_esti_dt,
		round(count(*) filter( where order_estimated_delivery_date is null)::numeric/count(*)*100,2) nulls_esti_dt_per
from bronze.olist_orders

--data consistency and format check
select *
from bronze.olist_orders
where order_status != trim(order_status)

--Distinct Dimensions check
select distinct order_status
from bronze.olist_orders

--date consistency check
select *
from bronze.olist_orders
where --order_purchase_timestamp>order_approved_at or 
		order_purchase_timestamp>order_delivered_carrier_date or--166 rows
		--order_purchase_timestamp>=order_delivered_customer_date or 
		--order_purchase_timestamp>=order_estimated_delivery_date


select *
from bronze.olist_orders
where order_approved_at>=order_delivered_carrier_date or--1359 rows
		order_approved_at>=order_delivered_customer_date or --61 rows
		order_approved_at>=order_estimated_delivery_date--12 rows

select *
from bronze.olist_orders
where order_delivered_carrier_date>=order_delivered_customer_date --32 rows

select *
from bronze.olist_orders
where order_estimated_delivery_date<=order_delivered_carrier_date

--=======================================================================================================

-------------------------------------------------
--initial EDA on bronze.olist_order_payments
-------------------------------------------------

select * from bronze.olist_order_payments--103886


--duplicate and null check in keys columns
select count(distinct order_id) from bronze.olist_order_payments--distinct order_id=99440

select *
from (select * , count(order_id) over(partition by order_id) cn
		from bronze.olist_order_payments) t1
where cn>1

--full row duplicate check
select *
from (select * , count(order_id) over(partition by order_id, payment_sequential, payment_type, payment_installments, payment_value) cn
		from bronze.olist_order_payments) t1
where cn>1

--nulls count check

select
		count(*) total_rows,
		
		count(*) filter( where order_id is null) nulls_order_id,
		round(count(*) filter( where order_id is null)::numeric/count(*)*100,2) nulls_order_id_per,
		
		count(*) filter( where payment_sequential is null) nulls_sequen,
		round(count(*) filter( where payment_sequential is null)::numeric/count(*)*100,2) nulls_sequen_per,
		
		count(*) filter( where payment_type is null) nulls_type,
		round(count(*) filter( where payment_type is null)::numeric/count(*)*100,2) nulls_type_per,
		
		count(*) filter( where payment_installments is null) nulls_installments,
		round(count(*) filter( where payment_installments is null)::numeric/count(*)*100,2) nulls_installments_per,
		
		count(*) filter( where payment_value is null) nulls_value,
		round(count(*) filter( where payment_value is null)::numeric/count(*)*100,2) nulls_value_per

from bronze.olist_order_payments

--data consistency and format check

select *
from bronze.olist_order_payments
where payment_installments<=0--****getting installments=0***--
/*

where order_id in ('744bade1fcf9ff3f31d860ace076d422',
'1a57108394169c0b47d8f876acc9ba2d')
--
SELECT 
    o.order_id,
    oi.total_order_value,   -- from your pre-aggregated order_items (price + freight)
    op.payment_value        -- the one row you have
FROM olist_orders o
JOIN (SELECT order_id, SUM(price + freight_value) AS total_order_value FROM olist_order_items GROUP BY order_id) oi
    ON o.order_id = oi.order_id
JOIN olist_order_payments op
    ON o.order_id = op.order_id
WHERE o.order_id IN ('744bade1fcf9ff3f31d860ace076d422', '1a57108394169c0b47d8f876acc9ba2d');
*/

select *
from bronze.olist_order_payments
where payment_value<=0

SELECT op.order_id, COUNT(*) AS total_payment_rows, SUM(op.payment_value) AS total_paid,
       oi.total_order_value
FROM olist_order_payments op
JOIN (SELECT order_id, SUM(price + freight_value) AS total_order_value FROM olist_order_items GROUP BY order_id) oi
    ON op.order_id = oi.order_id
WHERE op.order_id IN (
    SELECT order_id FROM olist_order_payments WHERE payment_value = 0
)
GROUP BY op.order_id, oi.total_order_value;

--extra space check

select *
from bronze.olist_order_payments
where payment_type != trim(payment_type)

--distinct dimensions check "744bade1fcf9ff3f31d860ace076d422"
"1a57108394169c0b47d8f876acc9ba2d"
select distinct payment_type
from bronze.olist_order_payments

--=======================================================================================================

-------------------------------------------------
--initial EDA on bronze.olist_order_reviews
-------------------------------------------------

select * from bronze.olist_order_reviews;--99224 rows

--duplicate check on key columns
select *
from (select *, count(*) over(partition by review_id,order_id) cn
from bronze.olist_order_reviews) t1 
where cn>1
--since same review_id were found for different order_id, verifing whether its from same customer because review request mail were sent in batched for 2 orders combined.
with od1 as
(select o.order_id, c.customer_unique_id
from olist_orders o left join olist_customers c using(customer_id))

select o.order_id, o.customer_unique_id, r.*
from od1 o left join (select *
from (select *, count(review_id) over(partition by review_id) cn
from bronze.olist_order_reviews) t1 
where cn>1) r using(order_id)
where r.order_id is not null
order by r.review_id

--just duplicate check for order_id
select *
from (select *, count(*) over(partition by order_id) cn
from bronze.olist_order_reviews) t1 
where cn>1

--full row duplicate check
select *
from (select *, count(*) over(partition by review_id,order_id,review_score, review_comment_title, review_comment_message, review_creation_date, review_answer_timestamp) cn
from bronze.olist_order_reviews) t1 
where cn>1

--null count check

select 
		count(*) total_rows,

		count(*) filter( where review_id is null) nulls_review_id,
		round(count(*) filter( where review_id is null)::numeric/count(*)*100,2) nulls_review_id_per,
		
		count(*) filter( where order_id is null) nulls_order_id,
		round(count(*) filter( where order_id is null)::numeric/count(*)*100,2) nulls_order_id_per,
		
		count(*) filter( where review_score is null) nulls_review_score,
		round(count(*) filter( where review_score is null)::numeric/count(*)*100,2) nulls_review_score_per,
		
		count(*) filter( where review_comment_title is null) nulls_comment_title,
		round(count(*) filter( where review_comment_title is null)::numeric/count(*)*100,2) nulls_comment_title_per,
		
		count(*) filter( where review_comment_message is null) nulls_message,
		round(count(*) filter( where review_comment_message is null)::numeric/count(*)*100,2) nulls_message_per,
		
		count(*) filter( where review_creation_date is null) nulls_creation_dt,
		round(count(*) filter( where review_creation_date is null)::numeric/count(*)*100,2) nulls_creation_dt_per,

		count(*) filter( where review_answer_timestamp is null) nulls_answer_ts,
		round(count(*) filter( where review_answer_timestamp is null)::numeric/count(*)*100,2) nulls_answer_ts_per
from bronze.olist_order_reviews

--distinct dimension check

select distinct review_score
from bronze.olist_order_reviews

--date consistency and format check

select *
from bronze.olist_order_reviews
where review_creation_date > review_answer_timestamp

--=======================================================================================================

-------------------------------------------------
--initial EDA on bronze.olist_products
-------------------------------------------------

select * from bronze.olist_products;--32951

--Duplicate and null check on key columns
select *
from (select *, count(product_id) over(partition by product_id) cn
from bronze.olist_products)
where cn>1 and product_id is null

--full row duplicate check
select *
from (select *, count(product_id) over(partition by product_id, product_category_name, product_name_length,
						product_description_length, product_photos_qty, product_weight_g, product_length_cm, product_height_cm, product_width_cm) cn
from bronze.olist_products)
where cn>1

--fan out risk check
select count(*) --112650
from bronze.olist_order_items

select count(*)
from bronze.olist_order_items i left join bronze.olist_products p using(product_id)

--Null count check

select
		count(*) total_rows,

		count(*) filter( where product_id is null) nulls_product_id,
		round(count(*) filter( where product_id is null)::numeric/count(*)*100,2) nulls_product_id_per,
		
		count(*) filter( where product_category_name is null) nulls_cat_name,
		round(count(*) filter( where product_category_name is null)::numeric/count(*)*100,2) nulls_cat_name_per,
		
		count(*) filter( where product_name_length is null) nulls_name_len,
		round(count(*) filter( where product_name_length is null)::numeric/count(*)*100,2) nulls_name_len_per,
		
		count(*) filter( where product_description_length is null) nulls_desp_len,
		round(count(*) filter( where product_description_length is null)::numeric/count(*)*100,2) nulls_desp_len_per,
		
		count(*) filter( where product_photos_qty is null) nulls_foto_qty,
		round(count(*) filter( where product_photos_qty is null)::numeric/count(*)*100,2) nulls_foto_qty_per,
		
		count(*) filter( where product_weight_g is null) nulls_wgth_g,
		round(count(*) filter( where product_weight_g is null)::numeric/count(*)*100,2) nulls_wgth_g_per,

		count(*) filter( where product_length_cm is null) nulls_len_cm,
		round(count(*) filter( where product_length_cm is null)::numeric/count(*)*100,2) nulls_len_cm_per,

		count(*) filter( where product_height_cm is null) nulls_height,
		round(count(*) filter( where product_height_cm is null)::numeric/count(*)*100,2) nulls_height_per,

		count(*) filter( where product_width_cm is null) nulls_width,
		round(count(*) filter( where product_width_cm is null)::numeric/count(*)*100,2) nulls_width_per
from bronze.olist_products

--Duplicate check for category name
select *
from (select *, count(product_category_name) over(partition by product_category_name) cn
from bronze.olist_products)
where cn>1

--extra space check
select *
from bronze.olist_products
where product_id != trim(product_id)

--distinct dimensions check
select distinct product_category_name
from bronze.olist_products

--data consistency and format
select *
from bronze.olist_products
where --product_name_length<=0 or 
	  --product_description_length<=0 or
	  --product_photos_qty<=0 or
	    product_weight_g<=0 or --4 row, value=0
	  --product_length_cm<=0 or
	  --product_height_cm<=0 or
	  --product_width_cm<=0
	  
--checking the english name of the category
select *
from bronze.olist_product_translation
where  product_category_name='cama_mesa_banho'

--checking does this product exists in order_Items
SELECT * FROM olist_order_items WHERE product_id IN (
    SELECT product_id FROM olist_products WHERE product_weight_g = 0
);

--=======================================================================================================

-------------------------------------------------
--initial EDA on bronze.olist_sellers
-------------------------------------------------

select * from bronze.olist_sellers;--3095 - rows total

--duplicates and null in key columns
select *
from (select *, count(seller_id) over(partition by seller_id) cn
from bronze.olist_sellers)
where cn>1

--full rows duplicate check
select *
from (select *, count(seller_id) over(partition by seller_id, seller_zip_code_prefix, seller_city, seller_state) cn
from bronze.olist_sellers)
where cn>1

--fan out risk check
select count(*)--112650
from bronze.olist_order_items

select count(*)--112650
from bronze.olist_order_items i left join bronze.olist_sellers s using(seller_id)

--Null count check

select
		count(*) total_rows,

		count(*) filter( where seller_id is null) nulls_seller_id,
		round(count(*) filter( where seller_id is null)::numeric/count(*)*100,2) nulls_seller_id_per,
		
		count(*) filter( where seller_zip_code_prefix is null) nulls_zipcode,
		round(count(*) filter( where seller_zip_code_prefix is null)::numeric/count(*)*100,2) nulls_zipcode_per,
		
		count(*) filter( where seller_city is null) nulls_city,
		round(count(*) filter( where seller_city is null)::numeric/count(*)*100,2) nulls_city_per,
		
		count(*) filter( where seller_state is null) nulls_state,
		round(count(*) filter( where seller_state is null)::numeric/count(*)*100,2) nulls_state_per

from bronze.olist_sellers

--Extra space check
select *
from bronze.olist_sellers
where seller_state != trim(seller_state)

--distinct dimensions check
select distinct seller_city
from bronze.olist_sellers

--data consistency and format check
select *
from bronze.olist_sellers
where seller_zip_code_prefix<0

--=======================================================================================================

---------------------------------------------------
--initial EDA on bronze.olist_product_translation
---------------------------------------------------
select * from bronze.olist_product_translation;--71 -total rows

--Duplicate and null check on key columns
select *
from (select *, count(*) over(partition by product_category_name) cn
from bronze.olist_product_translation)
where cn>1

--full row duplicate check
select *
from (select *, count(*) over(partition by product_category_name, product_category_name_english) cn
from bronze.olist_product_translation)
where cn>1

--fan out risk check
select count(*) from bronze.olist_products;--32951

select count(*) from bronze.olist_products p left join bronze.olist_product_translation t using(product_category_name)--32951

--Null count check
select 
		count(*) total_rows,

		count(*) filter( where product_category_name is null) nulls_cat_name,
		round(count(*) filter( where product_category_name is null)::numeric/count(*)*100,2) nulls_cat_name_per,
		
		count(*) filter( where product_category_name_english is null) nulls_name_trans,
		round(count(*) filter( where product_category_name_english is null)::numeric/count(*)*100,2) nulls_name_trans_per

from bronze.olist_product_translation

--data consistency and format check
select *
from bronze.olist_product_translation
where product_category_name_english != trim(product_category_name_english)

--distinct dimensions check
select distinct product_category_name
from bronze.olist_product_translation

select distinct product_category_name_english
from bronze.olist_product_translation

