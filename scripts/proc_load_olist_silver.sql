/*
=======================================================================================================
  Silver_layer: Loading cleaned and transformed data into the silver layer
=======================================================================================================
Source: Load the data from Bronze layer - dpcrd_olist.bronze

Purpose:
	1. creating stored procedure to insert the cleaned and transformed data into the silver layer.
	2. Check the data qulity before and after loading the data into silver layer
	3. created stored procedure for inserting data cause we'll be frequently running this insert operation.

Highlight:
	- Duplicate removal
	- Null handling
	- data standardisation and normalisation 
	- Date inconsistency fix
	- Fixing the data types
	- Data integration

Warning:
	- Each time when you run the procedure to load the data, it will empty the table first and then insert the new data.
	- Take a backup of the old data if its important

Parameters:
	- Store procedure doesn't accept parameters or return any value

Execution:
	call silver.load_olist_silver(); --calling the stored procedure

=======================================================================================================
*/

--Executing the procedure

call silver.load_olist_silver();

--Creating the Store procedure for loading data into silver layer...

drop procedure silver.load_olist_silver;--delete procedure 

create or replace procedure silver.load_olist_silver ()

language plpgsql as
$$

declare
		batch_start_time timestamp;
		batch_end_time timestamp;
		start_time timestamp;
		end_time timestamp;

begin

				batch_start_time := clock_timestamp(); --** for Perfect time calculation **
				Raise notice '================================================';
				Raise notice 	  'Loading data into silver.olist_customers';
				Raise notice '================================================';
				raise notice '   ';

				start_time:=clock_timestamp();
				Raise notice 	  '>> Truncates table silver.olist_customers';
				raise notice '   ';
				truncate table silver.olist_customers;
				
				Raise notice 	  '>> Inserting data into silver.olist_customers';
				raise notice '   ';
				
						insert into silver.olist_customers
						(
								customer_id,
								customer_unique_id,
								customer_zip_code_prefix,
								customer_city,
								customer_state
						)
						
						select  
								customer_id,
								customer_unique_id,
								customer_zip_code_prefix,
								initcap(trim(unaccent(customer_city))) customer_city,
								upper(trim(customer_state)) customer_state
						from bronze.olist_customers;

				end_time:=clock_timestamp();
				raise notice '>>Load Duration: %' , (end_time - start_time);
				raise notice ' ';
				
				Raise notice '================================================';
				Raise notice 	'Loading data into silver.olist_geolocation';
				Raise notice '================================================';
				raise notice '   ';
				start_time:=clock_timestamp();
				
				Raise notice 	'>> Truncates table silver.olist_geolocation';
				raise notice '   ';
				truncate table silver.olist_geolocation;
				
				Raise notice 	'>> Inserting data into silver.olist_geolocation';
				raise notice '   ';
				
						insert into silver.olist_geolocation
						(
								geolocation_zip_code_prefix,
								geolocation_lat,
								geolocation_lng,
								geolocation_city,
								geolocation_state
						
						)
						
						select
								geolocation_zip_code_prefix,
								geolocation_lat,
								geolocation_lng,
								initcap(
									trim(
										regexp_replace(
											unaccent(case when geolocation_city in ('4º centenario','4o. centenario') then 'cuarto centenario'
											else geolocation_city end),'[^A-Za-z0-9]',' ','g'
										)
									)
								) geolocation_city,
								upper(trim(geolocation_state)) geolocation_state
						from bronze.olist_geolocation
						group by 1,2,3,4,5;

				end_time:=clock_timestamp();
				raise notice '>>Load Duration: %' , (end_time - start_time);
				raise notice ' ';
				
				Raise notice '===================================================';
				Raise notice 	 'Loading data into silver.olist_order_payments';
				Raise notice '===================================================';
				raise notice '   ';
				start_time:=clock_timestamp();
				
				Raise notice 	 '>> Truncates table silver.olist_order_payments';
				raise notice '   ';
				truncate table silver.olist_order_payments;
				
				Raise notice 	'>> Inserting data into silver.olist_order_payments';
				raise notice '   ';
				
						insert into silver.olist_order_payments(
								
								order_id,
								payment_sequential,
								payment_type,
								payment_installments,
								payment_value
						)
						
						select 
								order_id,
								payment_sequential,
								initcap(
										trim(
											regexp_replace( payment_type, '[^A-Za-z0-9]',' ','g')
											)
										) payment_type,
								payment_installments,
								payment_value
								
						from bronze.olist_order_payments;

				end_time:=clock_timestamp();
				raise notice '>>Load Duration: %' , (end_time - start_time);
				raise notice ' ';
				
				Raise notice '================================================';
				Raise notice 	  'Loading data into silver.olist_products';
				Raise notice '================================================';
				raise notice '   ';
				start_time:=clock_timestamp();
				
				Raise notice 	  '>> Truncates table silver.olist_products';
				raise notice '   ';
				truncate table silver.olist_products;
				
				Raise notice 	 '>> Inserting data into silver.olist_products';
				raise notice '   ';
				
						insert into silver.olist_products(
								
								product_id,
								product_category_name,
								product_name_length,
								product_description_length,
								product_photos_qty,
								product_weight_g,
								product_length_cm,
								product_height_cm,
								product_width_cm
						)
						
						select
								product_id,
								coalesce(initcap(
									trim(
										regexp_replace(product_category_name_english, '[^A-Za-z0-9]',' ','g')
									)
								), 'n\a')  product_category_name_english,
								product_name_length,
								product_description_length,
								product_photos_qty,
								nullif(product_weight_g,0) product_weight_g,
								product_length_cm,
								product_height_cm,
								product_width_cm
								
						from bronze.olist_products p left join bronze.olist_product_translation t using(product_category_name);

				end_time:=clock_timestamp();
				raise notice '>>Load Duration: %' , (end_time - start_time);
				raise notice ' ';
				
				Raise notice '================================================';
				Raise notice 	  'Loading data into silver.olist_sellers';
				Raise notice '================================================';
				raise notice '   ';
				start_time:=clock_timestamp();
				
				Raise notice 	  '>> Truncates table silver.olist_sellers';
				raise notice '   ';
				truncate table silver.olist_sellers;
				
				Raise notice 	  '>> Inserting data into silver.olist_sellers';
				raise notice '   ';
				
						insert into silver.olist_sellers(
						
								seller_id,
								seller_zip_code_prefix,
								seller_city,
								seller_state
						)
						
						select
								seller_id,
								seller_zip_code_prefix,
								initcap(
										trim(
												case when seller_city in ('sp / sp', 'sao paluo', 'sao paulo sp','sao paulop','sao pauo','sp') then 'sao paulo'
													when seller_city in  ('sbc/sp','sbc') then 'Sao Bernardo do Campo'
													when seller_city in ('brasilia df') then 'brasilia'
													when seller_city in  ('04482255','vendas@creditparts.com.br') then 'n\a'
													when seller_city in ('rio de janeiro \rio de janeiro') then 'rio de janeiro'
													when seller_city in ('sao bernardo do capo') then 'sao bernardo do campo'
													when seller_city in ('sao jose do rio pret') then 'sao jose do rio preto'
													when seller_city in ('sao jose dos pinhas') then 'sao jose dos pinhais'
													when seller_city in ('tabao da serra') then 'taboao da serra'
													when seller_city like  'sao miguel%' then 'sao miguel do oeste'
													else regexp_replace(unaccent(regexp_replace(seller_city,'[''\´]',' ','g')),'[-/\,].*$','') end
															   )
										) seller_city,
								upper(trim(seller_state)) seller_state
								
						from bronze.olist_sellers;

				end_time:=clock_timestamp();
				raise notice '>>Load Duration: %' , (end_time - start_time);
				raise notice ' ';
				
				Raise notice '=====================================================';
				Raise notice 	  'Loading data into silver.olist_order_reviews';
				Raise notice '=====================================================';
				raise notice '   ';
				start_time:=clock_timestamp();
				
				Raise notice 	  '>> Truncates table silver.olist_order_reviews';
				raise notice '   ';
				
				truncate table silver.olist_order_reviews;
				
				Raise notice 	'>> Inserting data into silver.olist_order_reviews';
				raise notice '   ';
				
						insert into silver.olist_order_reviews(
								review_id,
								order_id,
								review_score,
								review_comment_title,
								review_comment_message,
								review_creation_date,
								review_answer_timestamp
						)
						
						select 
								review_id,
								order_id,
								review_score,
								trim(coalesce(unaccent(review_comment_title), 'n\a')) review_comment_title,
								trim(coalesce(unaccent(review_comment_message), 'n\a')) review_comment_message,
								review_creation_date,
								review_answer_timestamp
						
						from bronze.olist_order_reviews;

				end_time:=clock_timestamp();
				raise notice '>>Load Duration: %' , (end_time - start_time);
				raise notice ' ';
				
				Raise notice '==========================================================';
				Raise notice 	  'Loading data into silver.olist_product_translation';
				Raise notice '==========================================================';
				raise notice '   ';
				start_time:=clock_timestamp();
				
				Raise notice 	  '>> Truncates table silver.olist_product_translation';
				truncate table silver.olist_product_translation;
				raise notice '   ';
				
				Raise notice 	'>> Inserting data into silver.olist_product_translation';
				raise notice '   ';
				
						insert into silver.olist_product_translation(
						
								product_category_name,
								product_category_name_english
						)
						
						select 
								product_category_name,
								initcap(
									trim(
										regexp_replace(product_category_name_english, '[^A-Za-z0-9]',' ','g')
									)
								) product_category_name_english
								
						from bronze.olist_product_translation;

				end_time:=clock_timestamp();
				raise notice '>>Load Duration: %' , (end_time - start_time);
				raise notice ' ';
				
				Raise notice '================================================';
				Raise notice 	  'Loading data into silver.olist_order_items';
				Raise notice '================================================';
				raise notice '   ';
				start_time:=clock_timestamp();
				
				Raise notice 	  '>> Truncates table silver.olist_order_items';
				raise notice '   ';
				truncate table silver.olist_order_items;
				
				Raise notice 	'>> Inserting data into silver.olist_order_items';
				raise notice '   ';
				
						insert into silver.olist_order_items(
						
								order_id,
								order_item_id,
								product_id,
								seller_id,
								shipping_limit_date,
								price,
								freight_value
						
						)
						
						select
								order_id,
								order_item_id,
								product_id,
								seller_id,
								shipping_limit_date,
								price,
								freight_value
								
						from bronze.olist_order_items;
						
				end_time:=clock_timestamp();
				raise notice '>>Load Duration: %' , (end_time - start_time);
				raise notice ' ';
				
				
				Raise notice '================================================';
				Raise notice 	  'Loading data into silver.olist_orders';
				Raise notice '================================================';
				raise notice '   ';
				start_time:=clock_timestamp();
				
				Raise notice 	  '>> Truncates table silver.olist_orders';
				truncate table silver.olist_orders;
				raise notice '   ';
				
				Raise notice 	'>> Inserting data into silver.olist_orders';
				raise notice '   ';
				
						insert into silver.olist_orders(
						
								order_id,
								customer_id,
								order_status,
								order_purchase_timestamp,
								order_approved_at,
								order_delivered_carrier_date,
								order_delivered_customer_date,
								order_estimated_delivery_date,
								has_invalid_timestamp_sequence
						)
						
						select 
								order_id,
								customer_id,
								initcap(trim(order_status)) order_status,
								order_purchase_timestamp,
								order_approved_at,
								order_delivered_carrier_date,
								order_delivered_customer_date,
								order_estimated_delivery_date,
								CASE 
								    WHEN order_purchase_timestamp > order_delivered_carrier_date
								      OR order_approved_at > order_delivered_carrier_date
								      OR order_approved_at > order_delivered_customer_date
								      OR order_delivered_carrier_date > order_delivered_customer_date
								    THEN TRUE ELSE FALSE
									END AS has_invalid_timestamp_sequence
						
						from bronze.olist_orders;

				end_time:=clock_timestamp();
				raise notice '>>Load Duration: %' , (end_time - start_time);
				raise notice ' ';
				
				raise notice '===================================';
				raise notice '	Data Loading Completed		';
				raise notice '===================================';
				raise notice ' ';
				
				batch_end_time := clock_timestamp();
				
				raise notice ' Load time for the whole session:';
				raise notice '>> Batch Starting time: %', batch_start_time;
				raise notice '>> Batch End time: %', batch_end_time;
				raise notice '>> Total duration to load all the data into silver layer: %' , (batch_end_time - batch_start_time) ;

				exception
				when others then 
				raise notice '>> Error occured while loading the data:';
				raise notice '>>Error Message: %', SQLERRM;

end $$;

--====================================================
-- Loading data into silver.olist_payments_agg
--====================================================

				truncate table silver.olist_payments_agg;
				
				create table silver.olist_payments_agg as
				with payments_ranked as
							(
								select *, row_number() over(partition by order_id order by payment_value desc) rn
							 	from bronze.olist_order_payments
							 ),
				primary_payments as
							(
								select order_id, payment_type primary_payment_type
								from payments_ranked
								where rn=1
							)
				
				select
						op.order_id,
						count(*) payment_sequential_cn,
						count(distinct payment_type) num_payment_type,
						max(payment_installments) payment_installments,
						sum(payment_value) total_payment_value,
						initcap(
							trim(
								regexp_replace(primary_payment_type, '[^A-Za-z]',' ', 'g')
							)
						) primary_payment_type
						
				from bronze.olist_order_payments op join primary_payments pp using(order_id)
				group by op.order_id, primary_payment_type;
				



--====================================================
-- Loading data into silver.olist_order_items_agg
--====================================================

			truncate table silver.olist_order_items_agg;
			
			create table silver.olist_order_items_agg as
			select 
					order_id,
					count(order_item_id) num_items,
					count(distinct product_id) num_distinct_products,
					count(distinct seller_id) num_distinct_sellers,
					min(shipping_limit_date) shipping_limit_date,
					sum(price) total_item_price,
					sum(freight_value) total_freight_value,
					sum(price+freight_value) total_order_value
					
			from bronze.olist_order_items
			group by order_id;













