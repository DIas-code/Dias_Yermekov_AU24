/*
 Task 1
Create a query to produce a sales report highlighting the top customers with the highest sales 
across different sales channels. This report should list the top 5 customers for each channel. 
Additionally, calculate a key performance indicator (KPI) called 'sales_percentage,' 
which represents the percentage of a customer's sales relative to the total sales within their respective channel.
Please format the columns as follows:
Display the total sales amount with two decimal places
Display the sales percentage with five decimal places and include the percent sign (%) at the end
Display the result for each channel in descending order of sales
 */
WITH total_amount_cte AS ( -- Find totals FOR further ranking
SELECT
	c.channel_desc,
	s.cust_id,
	CONCAT(cu.cust_first_name, ' ', cu.cust_last_name) AS customer_name,
	SUM(s.amount_sold) AS total_amount,
	SUM(SUM(s.amount_sold)) OVER (PARTITION BY s.channel_id) AS channel_total_amount
FROM
	sh.sales s
JOIN 
	sh.channels c ON s.channel_id = c.channel_id
JOIN 
	sh.customers cu ON s.cust_id = cu.cust_id
GROUP BY
	c.channel_desc,
	s.cust_id,
	cu.cust_first_name,
	cu.cust_last_name,
	s.channel_id
),
ranked AS ( -- ranking BY total sales
SELECT
	tsc.channel_desc,
	tsc.cust_id,
	tsc.customer_name,
	ROUND(tsc.total_amount, 2) AS total_amount,
	ROUND((tsc.total_amount / tsc.channel_total_amount) * 100, 5) || '%' AS sales_percentage,
	RANK() OVER (PARTITION BY channel_desc ORDER BY total_amount DESC) AS rn
FROM
	total_amount_cte tsc
)
SELECT
	channel_desc,
	customer_name,
	total_amount,
	sales_percentage
FROM
	ranked
WHERE
	rn <= 5
ORDER BY
	channel_desc,
	total_amount DESC;

/*
 Task 2
Create a query to retrieve data for a report that displays the total sales for all products 
in the Photo category in the Asian region for the year 2000. 
Calculate the overall report total and name it 'YEAR_SUM'
Display the sales amount with two decimal places
Display the result in descending order of 'YEAR_SUM'
For this report, consider exploring the use of the crosstab function. 
Additional details and guidance can be found at this link
*/

--SELECT * FROM sh.times t; 
CREATE EXTENSION IF NOT EXISTS tablefunc;

WITH quarters AS (
SELECT
	*
FROM
	crosstab(
    'SELECT --row generation
        p.prod_name AS product_name, -- 1 column row identifier
        t.fiscal_quarter_number AS quarter, -- rows
        SUM(s.amount_sold) AS total_amount
     FROM 
        sh.sales s
     JOIN 
        sh.products p ON s.prod_id = p.prod_id
     JOIN 
        sh.customers c ON s.cust_id = c.cust_id
     JOIN 
        sh.countries co ON c.country_id = co.country_id
     JOIN 
        sh.times t ON s.time_id = t.time_id
     WHERE 
        p.prod_category = ''Photo'' 
        AND co.country_region = ''Asia'' 
        AND t.calendar_year = 2000
     GROUP BY 
        p.prod_name, t.fiscal_quarter_number
     ORDER BY 
        p.prod_name, t.fiscal_quarter_number',
	'SELECT DISTINCT fiscal_quarter_number FROM sh.times ORDER BY fiscal_quarter_number' -- VALUES FOR columns
) AS ct(product_name TEXT, q1 NUMERIC, q2 NUMERIC, q3 NUMERIC, q4 NUMERIC))
SELECT
	*,
	COALESCE(q1, 0) + COALESCE(q2, 0) + COALESCE(q3, 0) + COALESCE(q4, 0) AS total_year_amount
FROM
	quarters
ORDER BY
	total_year_amount DESC;
	
/*
 Task 3
Create a query to generate a sales report for customers ranked in the top 300 based on total 
sales in the years 1998, 1999, and 2001. The report should be categorized based on sales channels, 
and separate calculations should be performed for each channel.
Retrieve customers who ranked among the top 300 in sales for the years 1998, 1999, and 2001
Categorize the customers based on their sales channels
Perform separate calculations for each sales channel
Include in the report only purchases made on the channel specified
Format the column so that total sales are displayed with two decimal places
*/
WITH amount_per_year_channel AS ( -- Finding amount FOR EACH YEAR AND channel
SELECT
	s.cust_id,
	c.cust_first_name,
	c.cust_last_name,
	s.channel_id,
	ch.channel_desc,
	SUM(s.amount_sold) AS total_amount,
	t.calendar_year
FROM
	sh.sales s
JOIN
	sh.customers c ON s.cust_id = c.cust_id
JOIN
	sh.channels ch ON s.channel_id = ch.channel_id
JOIN 
	sh.times t ON s.time_id = t.time_id
WHERE
	t.calendar_year IN (1998, 1999, 2001)
GROUP BY
	s.cust_id,
	c.cust_first_name,
	c.cust_last_name,
	s.channel_id,
	ch.channel_desc,
	t.calendar_year
),
ranking  AS ( -- ranking 
    SELECT
	cust_id,
	channel_id,
	channel_desc,
	total_amount,
	calendar_year,
	RANK() OVER (PARTITION BY calendar_year, channel_id ORDER BY total_amount DESC) AS rn
FROM
	amount_per_year_channel
),
top_300_per_year_channel AS ( -- getting customers that IN top 300 by each YEAR AND category
SELECT
	cust_id,
	channel_id
FROM
	ranking
WHERE
	rn <= 300
GROUP BY
	cust_id,
	channel_id
HAVING
	COUNT(DISTINCT calendar_year) = 3
)
SELECT -- getting customers that in ranking and in top300 with additional columns.
	c.cust_first_name,
	c.cust_last_name,
	r.channel_desc,
	SUM(r.total_amount) AS total_amount
FROM
	ranking r
JOIN
    top_300_per_year_channel t3 ON r.cust_id = t3.cust_id AND r.channel_id = t3.channel_id
JOIN
    sh.customers c ON r.cust_id = c.cust_id
WHERE
	r.rn <= 300
GROUP BY
	r.cust_id,
	c.cust_first_name,
	c.cust_last_name,
	r.channel_desc
ORDER BY
	total_amount DESC;

/*
 Task 4
Create a query to generate a sales report for January 2000, February 2000, and March 2000 specifically for the Europe and Americas regions.
Display the result by months and by product category in alphabetical order.
*/

SELECT --simlpe query
	t.fiscal_month_desc,
	p.prod_category,
	SUM(CASE WHEN co.country_region = 'Americas' THEN s.amount_sold ELSE 0 END) AS americas_sales,
	SUM(CASE WHEN co.country_region = 'Europe' THEN s.amount_sold ELSE 0 END) AS europe_sales,
	SUM(s.amount_sold) AS total_amount
FROM
	sh.sales s
JOIN 
    sh.times t ON t.time_id = s.time_id
JOIN 
    sh.customers cu ON cu.cust_id = s.cust_id
JOIN 
    sh.countries co ON co.country_id = cu.country_id
JOIN 
    sh.products p ON p.prod_id = s.prod_id
WHERE
	t.fiscal_month_desc IN ('2000-01', '2000-02', '2000-03')
	AND co.country_region IN ('Europe', 'Americas')
GROUP BY
	t.fiscal_month_desc,
	p.prod_category
ORDER BY
	p.prod_category,
	t.fiscal_month_desc;

-- For this task, there is no need to use window functions, 
-- so I created another query with ranking by month to get the top 1 for each month by total amount
WITH ranking AS (
SELECT
	t.fiscal_month_desc,
	p.prod_category,
	SUM(CASE WHEN co.country_region = 'Americas' THEN s.amount_sold ELSE 0 END) AS americas_sales,
	SUM(CASE WHEN co.country_region = 'Europe' THEN s.amount_sold ELSE 0 END) AS europe_sales,
	SUM(s.amount_sold) AS total_amount,
	RANK() over(PARTITION BY t.fiscal_month_desc ORDER BY SUM(s.amount_sold)) AS rn
FROM
	sh.sales s
JOIN 
    sh.times t ON t.time_id = s.time_id
JOIN 
    sh.customers cu ON cu.cust_id = s.cust_id
JOIN 
    sh.countries co ON co.country_id = cu.country_id
JOIN 
    sh.products p ON p.prod_id = s.prod_id
WHERE
	t.fiscal_month_desc IN ('2000-01', '2000-02', '2000-03')
	AND co.country_region IN ('Europe', 'Americas')
GROUP BY
	t.fiscal_month_desc,
	p.prod_category
ORDER BY
	p.prod_category,
	t.fiscal_month_desc
) 
SELECT * FROM ranking
WHERE rn = 1
ORDER BY fiscal_month_desc;