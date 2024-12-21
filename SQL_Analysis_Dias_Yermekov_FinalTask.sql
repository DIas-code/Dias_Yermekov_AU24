/*
Task 1. Window Functions
Create a query to generate a report that identifies for each channel and throughout the entire period, the regions with the highest quantity of products sold (quantity_sold). 
The resulting report should include the following columns:
CHANNEL_DESC
COUNTRY_REGION
SALES: This column will display the number of products sold (quantity_sold) with two decimal places.
SALES %: This column will show the percentage of maximum sales in the region (as displayed in the SALES column) compared to the total sales for that channel. The sales percentage should be displayed with two decimal places and include the percent sign (%) at the end.
Display the result in descending order of SALES
 */

WITH channel_region_total AS (--getting sales BY country AND region
SELECT
	co.country_region,
	s.channel_id,
	ch.channel_desc,
	SUM(s.quantity_sold) AS total_by_cr
FROM
	sh.sales s
JOIN sh.customers c ON
	c.cust_id = s.cust_id
JOIN sh.countries co ON
	c.country_id = co.country_id
JOIN sh.channels ch ON
	ch.channel_id = s.channel_id
GROUP BY
	co.country_region,
	s.channel_id,
	ch.channel_desc
),
ranking AS ( --ranking BY sales
SELECT
	country_region,
	channel_id,
	channel_desc,
	total_by_cr, 
	RANK () OVER (PARTITION BY channel_id
	ORDER BY total_by_cr DESC) AS rn
FROM
	channel_region_total
),
channel_total AS (--gettin total sales FOR channel
SELECT
	s.channel_id,
	ch.channel_desc,
	SUM(s.quantity_sold) AS total_by_r
FROM
	sh.sales s
JOIN sh.customers c ON
	c.cust_id = s.cust_id
JOIN sh.channels ch ON
	ch.channel_id = s.channel_id
GROUP BY
	s.channel_id,
	ch.channel_desc
)
SELECT
	r.channel_desc,
	r.country_region,
	to_char(r.total_by_cr,
	'999,999,999.00') AS sales,
	to_char(total_by_cr / total_by_r * 100,
	'999,999,999.00%') AS "SALES%"
FROM
	ranking r
JOIN channel_total ct ON
	ct.channel_id = r.channel_id
WHERE
	rn <= 1
ORDER BY
	r.total_by_cr DESC;


/*
Task 2. Window Functions
Identify the subcategories of products with consistently higher sales from 1998 to 2001 compared to the previous year. 
Determine the sales for each subcategory from 1998 to 2001.
Calculate the sales for the previous year for each subcategory.
Identify subcategories where the sales from 1998 to 2001 are consistently higher than the previous year.
Generate a dataset with a single column containing the identified prod_subcategory values.
 */

WITH sales_by_subcat AS ( -- getting sales of amount(or quantity) BY subcategory AND year
SELECT
	t.calendar_year,
	p.prod_subcategory_id,
	p.prod_subcategory_desc,
	sum(s.amount_sold) AS sales
-- sum(s.quantity_sold) as sales --It can be used instead of the quatity sold if sales mean quantity.
FROM
	sh.sales s
JOIN sh.products p ON
	s.prod_id = p.prod_id
JOIN sh.times t ON
	s.time_id = t.time_id
GROUP BY
	t.calendar_year,
	p.prod_subcategory_id,
	p.prod_subcategory_desc
),
sales_by_subcat_wih_prevyear AS( -- getting sales of amount(or quantity) BY subcategory AND YEAR WITH previous YEAR sales
SELECT
	calendar_year,
	prod_subcategory_id,
	prod_subcategory_desc,
	sales,
	COALESCE(LAG(sales) OVER (PARTITION BY prod_subcategory_id
	ORDER BY calendar_year), 0) AS prev_sales
FROM
	sales_by_subcat),
higer_subcat AS ( --checking where the sales from 1998 to 2001 are consistently higher than the previous year
SELECT
	prod_subcategory_id,
	prod_subcategory_desc
FROM
	sales_by_subcat_wih_prevyear
WHERE
	calendar_year BETWEEN 1998 AND 2001
	AND sales > prev_sales
GROUP BY
	prod_subcategory_id,
	prod_subcategory_desc
HAVING
	count(*) = 4 
)
SELECT
	prod_subcategory_desc
FROM
	higer_subcat;

/*
Task 3. Window Frames
Create a query to generate a sales report for the years 1999 and 2000, focusing on quarters and product categories. 
In the report you have to  analyze the sales of products from the categories 'Electronics,' 'Hardware,' and 'Software/Other,' 
across the distribution channels 'Partners' and 'Internet'.

The resulting report should include the following columns:
CALENDAR_YEAR: The calendar year
CALENDAR_QUARTER_DESC: The quarter of the year
PROD_CATEGORY: The product category
SALES$: The sum of sales (amount_sold) for the product category and quarter with two decimal places
DIFF_PERCENT: Indicates the percentage by which sales increased or decreased compared to the first quarter of the year. 
For the first quarter, the column value is 'N/A.' The percentage should be displayed with two decimal places and include the percent sign (%) at the end.
CUM_SUM$: The cumulative sum of sales by quarters with two decimal places
The final result should be sorted in ascending order based on two criteria: 
first by 'calendar_year,' then by 'calendar_quarter_desc'; and finally by 'sales' descending
 */

WITH sales_by_q AS ( -- getting sum OF sales BY YEAR, quarter, category
SELECT
	t.calendar_year,
	t.calendar_quarter_desc,
	p.prod_category_id,
	p.prod_category,
	sum(s.amount_sold) AS sales
FROM
	sh.sales s
JOIN sh.times t ON
	t.time_id = s.time_id
JOIN sh.products p ON
	p.prod_id = s.prod_id
JOIN sh.channels c ON
	c.channel_id = s.channel_id
WHERE
	lower(p.prod_category) IN ('electronics', 'hardware', 'software/other')
	AND lower(c.channel_desc) IN ('partners', 'internet')
	AND t.calendar_year IN (1999, 2000)
GROUP BY
	t.calendar_year,
	t.calendar_quarter_desc,
	p.prod_category_id,
	p.prod_category),
sales_by_q_calculation AS ( --getting VALUES FOR result
SELECT
	calendar_year,
	calendar_quarter_desc,
	prod_category_id,
	prod_category,
	sales,
	FIRST_VALUE(calendar_quarter_desc) OVER (PARTITION BY calendar_year
ORDER BY
	calendar_quarter_desc) first_q,
	FIRST_VALUE(sales) OVER (PARTITION BY calendar_year,
	prod_category_id
ORDER BY
	calendar_quarter_desc) q1_sales,
	--sum(sales) OVER (PARTITION BY calendar_year, prod_category_id ORDER BY calendar_quarter_desc RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_sum,
	sum(sales) OVER (PARTITION BY calendar_year
ORDER BY
	calendar_quarter_desc RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_sum_q
FROM
	sales_by_q)
SELECT
	calendar_year,
	calendar_quarter_desc,
	prod_category,
	to_char(sales,
	'999,999,999.00') AS "sales$",
	CASE
		WHEN calendar_quarter_desc = first_q THEN 'N/A'
		ELSE to_char(sales / q1_sales * 100 - 100,
		'999.00%')
	END AS DIFF_PERCENT,
	to_char(cum_sum_q,
	'999,999,999.00') AS cum_sum
FROM
	sales_by_q_calculation
--WHERE
--	first_q LIKE '%-01' --checking IF we have FIRST quarter
ORDER BY
	calendar_year ASC,
	calendar_quarter_desc ASC,
	sales DESC;





