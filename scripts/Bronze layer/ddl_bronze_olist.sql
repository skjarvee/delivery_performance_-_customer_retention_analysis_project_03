/*
================================================================================================ 
 Delivery Performance & Customer Retention Diagnostic — Multi-Category E-Commerce Marketplace
================================================================================================

================================================================================================ 
 DDL for Bronze
================================================================================================

Purpose:
	1. Creating table and defining the columns and data types in this bronze layer.

Warning:
	- it will delete the old table if exists and create new table structure, so take backup



================================================================================================
*/


--checking the schema selected
show search_path;--"bronze, public"

--creating the tables

do $$

begin
--creating bronze.orders
drop table if exists bronze.olist_orders;

create table bronze.olist_orders
(
		order_id	varchar(80),
		customer_id	varchar(80),
		order_status	varchar(50),
		order_purchase_timestamp	timestamp,
		order_approved_at	timestamp,
		order_delivered_carrier_date	timestamp,
		order_delivered_customer_date	timestamp,
		order_estimated_delivery_date	timestamp
);

--select * from bronze.olist_orders;

--creating bronze.olist_order_items

drop table if exists bronze.olist_order_items;

create table bronze.olist_order_items
(
		order_id	varchar(80),
		order_item_id	int,
		product_id	varchar(80),
		seller_id	varchar(80),
		shipping_limit_date	timestamp,
		price	numeric(18,2),
		freight_value	numeric(18,2)
);

--select * from bronze.olist_order_items;

--creating bronze.olist_customers

drop table if exists bronze.olist_customers;

create table bronze.olist_customers(
		customer_id	varchar(80),
		customer_unique_id	varchar(80),
		customer_zip_code_prefix	int,
		customer_city	varchar(80),
		customer_state	varchar(10)
)

--creating bronze.olist_


drop table if exists bronze.olist_geolocation;

create table bronze.olist_geolocation
(
		geolocation_zip_code_prefix	int,
		geolocation_lat	numeric,
		geolocation_lng	numeric,
		geolocation_city	varchar(50),
		geolocation_state varchar(10)
);

--creating bronze.olist_order_payments

drop table if exists bronze.olist_order_payments;

create table bronze.olist_order_payments
(
		order_id	varchar(80),
		payment_sequential	int,
		payment_type	varchar(50),
		payment_installments	int,
		payment_value	numeric(18,2)
);

--creatinge bronze.olist_order_reviews

drop table if exists bronze.olist_order_reviews;

create table bronze.olist_order_reviews
(
		review_id	varchar(80),
		order_id	varchar(80),
		review_score	int,
		review_comment_title	varchar,
		review_comment_message	varchar,
		review_creation_date	date,
		review_answer_timestamp timestamp
);

--creating bronze.olist_products

drop table if exists bronze.olist_products;

create table bronze.olist_products
(
		product_id	varchar(80),
		product_category_name	varchar(300),
		product_name_length	int,
		product_description_length	int,
		product_photos_qty	int,
		product_weight_g	int,
		product_length_cm	int,
		product_height_cm	int,
		product_width_cm	int
);


--creating bronze.olist_sellers

drop table if exists bronze.olist_sellers;

create table bronze.olist_sellers
(
		seller_id	varchar(80),
		seller_zip_code_prefix	int,
		seller_city	varchar(300),
		seller_state varchar(10)
);

--creating bronze.olist_product_translation

drop table if exists bronze.olist_product_translation;

create table bronze.olist_product_translation
(
		product_category_name	varchar(300),
		product_category_name_english	varchar(300)
);



end $$;
