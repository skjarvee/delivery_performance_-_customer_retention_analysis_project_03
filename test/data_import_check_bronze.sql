/*
================================================================================================ 
 Data import check
================================================================================================

Purpose:
	1. Loaded the data using import option in pgadim, just check every data is loaded on to their
	respective columns without error

================================================================================================
*/

--checking bronze.olist_customers

select * from bronze.olist_customers;

--checking bronze.olist_geolocation

select * from bronze.olist_geolocation;

--checking bronze.olist_order_items

select * from bronze.olist_order_items;

--checking bronze.olist_order_payments

select * from bronze.olist_order_payments;

--checking bronze.olist_order_reviews

select * from bronze.olist_order_reviews;

--checking bronze.olist_orders

select * from bronze.olist_orders;

--checking bronze.olist_product_translation

select * from bronze.olist_product_translation;

--checking bronze.olist_products

select * from bronze.olist_products;

--checking bronze.olist_sellers

select * from bronze.olist_sellers;
