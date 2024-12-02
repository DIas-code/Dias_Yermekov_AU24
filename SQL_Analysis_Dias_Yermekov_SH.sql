SELECT * FROM sh.times;
--SELECT DISTINCT p.prod_category FROM sh.products p ;
--SELECT DISTINCT * FROM sh.products p ;
--SELECT DISTINCT * FROM sh.countries c ;


--Task 3. Write SQL queries to perform the following tasks:
--Retrieve the total sales amount for each product category for a specific time period

SELECT p.prod_category, sum(s.amount_sold) AS total_category_amount 
FROM sh.sales s 
JOIN sh.products p using(prod_id)
-- NO need TO JOIN times cause time_id IS representation OF EVERY date FROM 1998 TO 2002 nearly
WHERE s.time_id BETWEEN '1998-01-08'::date AND '1998-01-15'::date 
GROUP BY p.prod_category ;

--Calculate the average sales quantity by region for a particular product

SELECT p.prod_name, c.country_region, 
	avg(s.quantity_sold) AS average_quantity_sold_of_product_by_region
FROM sh.countries c 
JOIN sh.customers c2 ON c.country_id = c2.country_id 
JOIN sh.sales s ON c2.cust_id = s.cust_id 
JOIN sh.products p ON s.prod_id = p.prod_id 
WHERE lower(p.prod_name) = lower('Internal 6X CD-ROM')
GROUP BY c.country_region, p.prod_name ;

--Find the top five customers with the highest total sales amount

SELECT c.cust_first_name, c.cust_last_name, 
	sum(s.amount_sold) AS total_amount_sold_by_customer 
FROM sh.customers c 
JOIN sh.sales s using(cust_id)
GROUP BY cust_id, c.cust_first_name, c.cust_last_name
ORDER BY total_amount_sold_by_customer DESC 
FETCH NEXT 5 ROWS WITH TIES;
