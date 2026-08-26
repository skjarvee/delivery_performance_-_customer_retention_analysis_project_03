/*
================================================================================================ 
 Delivery Performance & Customer Retention Diagnostic — Multi-Category E-Commerce Marketplace
================================================================================================

================================================================================================ 
 DDL for silver
================================================================================================

Purpose:
	1. Creating table and defining the columns and data types in this silver layer.

Warning:
	- it will delete the old table if exists and create new table structure, so take backup



================================================================================================
*/


--checking the schema selected
show search_path;--"silver, public"

set search_path to silver, bronze;

alter role postgres set search_path to silver, bronze;

--creating the tables
do $$

begin
raise notice '=========================================================';
raise notice '>> creating silver.orders' ;
raise notice '=========================================================';
drop table if exists silver.olist_orders;

create table silver.olist_orders
(
		order_id	varchar(80),
		customer_id	varchar(80),
		order_status	varchar(50),
		order_purchase_timestamp	timestamp,
		order_approved_at	timestamp,
		order_delivered_carrier_date	timestamp,
		order_delivered_customer_date	timestamp,
		order_estimated_delivery_date	timestamp,
		has_invalid_timestamp_sequence boolean,
		dwh_create_ts	timestamp default current_timestamp
);

--select * from silver.olist_orders;

raise notice '=========================================================';
raise notice '>> creating silver.olist_order_items' ;
raise notice '=========================================================';

drop table if exists silver.olist_order_items;

create table silver.olist_order_items
(
		order_id	varchar(80),
		order_item_id	int,
		product_id	varchar(80),
		seller_id	varchar(80),
		shipping_limit_date	timestamp,
		price	numeric(18,2),
		freight_value	numeric(18,2),
		dwh_create_ts	timestamp default current_timestamp
);

--select * from silver.olist_order_items;
raise notice '=========================================================';
raise notice '>> creating silver.olist_customers' ;
raise notice '=========================================================';

drop table if exists silver.olist_customers;

create table silver.olist_customers(
		customer_id	varchar(80),
		customer_unique_id	varchar(80),
		customer_zip_code_prefix	int,
		customer_city	varchar(80),
		customer_state	varchar(10),
		dwh_create_ts	timestamp default current_timestamp
);

raise notice '=========================================================';
raise notice '>> creating silver.olist_geolocation' ;
raise notice '=========================================================';

drop table if exists silver.olist_geolocation;

create table silver.olist_geolocation
(
		geolocation_zip_code_prefix	int,
		geolocation_lat	numeric,
		geolocation_lng	numeric,
		geolocation_city	varchar(50),
		geolocation_state varchar(10),
		dwh_create_ts	timestamp default current_timestamp
);

raise notice '=========================================================';
raise notice '>> creating silver.olist_order_payments' ;
raise notice '=========================================================';

drop table if exists silver.olist_order_payments;

create table silver.olist_order_payments
(
		order_id	varchar(80),
		payment_sequential	int,
		payment_type	varchar(50),
		payment_installments	int,
		payment_value	numeric(18,2),
		dwh_create_ts	timestamp default current_timestamp
);

raise notice '=========================================================';
raise notice '>> creatinge silver.olist_order_reviews' ;
raise notice '=========================================================';

drop table if exists silver.olist_order_reviews;

create table silver.olist_order_reviews
(
		review_id	varchar(80),
		order_id	varchar(80),
		review_score	int,
		review_comment_title	varchar,
		review_comment_message	varchar,
		review_creation_date	date,
		review_answer_timestamp timestamp,
		dwh_create_ts	timestamp default current_timestamp
);

raise notice '=========================================================';
raise notice '>> creating silver.olist_products' ;
raise notice '=========================================================';

drop table if exists silver.olist_products;

create table silver.olist_products
(
		product_id	varchar(80),
		product_category_name	varchar(300),
		product_name_length	int,
		product_description_length	int,
		product_photos_qty	int,
		product_weight_g	int,
		product_length_cm	int,
		product_height_cm	int,
		product_width_cm	int,
		dwh_create_ts	timestamp default current_timestamp
);

raise notice '=========================================================';
raise notice '>> creating silver.olist_sellers';
raise notice '=========================================================';

drop table if exists silver.olist_sellers;

create table silver.olist_sellers
(
		seller_id	varchar(80),
		seller_zip_code_prefix	int,
		seller_city	varchar(300),
		seller_state varchar(10),
		dwh_create_ts	timestamp default current_timestamp
);

raise notice '=========================================================';
raise notice '>> creating silver.olist_product_translation';
raise notice '=========================================================';

drop table if exists silver.olist_product_translation;

create table silver.olist_product_translation
(
		product_category_name	varchar(300),
		product_category_name_english	varchar(300),
		dwh_create_ts	timestamp default current_timestamp
);


end $$;

--created , just checking silver.olist_payments_agg

select * from silver.olist_payments_agg;

--created , just checking silver.olist_order_items_agg

select *
from silver.olist_order_items_agg;