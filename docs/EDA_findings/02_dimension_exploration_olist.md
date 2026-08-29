# 02 Dimension Exploration: Key Findings

## fact_o_orders:

### payment_types
   - There 5 different payments are available. (Credit card, Boleto, Voucher, Debit Card) and also some are "not defined"
   - Credit card is used for 75.40%(74975) of orders and Boleto payment type for 19.90% (19784)

### delivery_status
   - 7.87%(7827) are delivery were late out of 99441 orders and 89.15% (88649) of orders were delivered on time.
   - delivery date has some null values, 2965(2.98%) are null values.
   - delivery status has bucket of two category("On Time","Late","null")

## dim_o_products:

### product category
   - There 72 distinct category being sold.
   - Bed bath table category is the most sold category with 11115(9.80%) orders
   - 1627(1.43%) orders doesn't have the category name or product name , so their value is "n\a"

## dim_o_customers:
   - 96096 unique customers
     
### customer state
   - 27 unique states and 4119 cities, all the states in the brazil.
   - Most of the customers are from "Sao Paulo" state, 	40302	(41.92%) of unique customers are live in Sao Paulo.
   - "Roraima"	state has least customer  of 45	(0.05%)

## dim_o_sellers:
   - 3095 unique sellers

### seller state
   - 23 unique states.
   - 1849(59.74%) of sellers are from "Sao Paulo" state

## Flagged forward
   - SP dominates both customers (42%) and sellers (60%) — state-level rankings in 
     Magnitude/Ranking analysis need to account for this scale imbalance
   - 1,627 orders (1.43%) have no product category — check if these cluster in 
     specific sellers or if it's random before Magnitude analysis















