--show search_path;

/*
============================================================
DataBase Exploration
============================================================

Purpose:
1. explore the tables and columns in the database
2. check the datatypes of the columns

============================================================
*/

--Checking distinct schemas

select distinct table_schema
from information_schema.tables;

select *
from information_schema.tables;

--checking columns

select *
from information_schema.columns
where table_schema = 'gold'
order by table_schema, table_name;

--EXploraing the colums particular table

select *
from information_schema.columns
where table_schema = 'gold' and table_name = 'fact_o_orders'
order by ordinal_position;