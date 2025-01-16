/*
Task 1
Create a query for analyzing the annual sales data for the years 1999 to 2001,
focusing on different sales channels and regions: 'Americas,' 'Asia,' and 'Europe.'
The resulting report should contain the following columns:
AMOUNT_SOLD: This column should show the total sales amount for each sales channel
% BY CHANNELS: In this column, we should display the percentage of total sales for each channel
(e.g. 100% - total sales for Americas in 1999, 63.64% - percentage of sales for the channel “Direct Sales”)
% PREVIOUS PERIOD: This column should display the same percentage values as in the '% BY CHANNELS' column but for the previous year
% DIFF: This column should show the difference between the '% BY CHANNELS' and '% PREVIOUS PERIOD' columns,
indicating the change in sales percentage from the previous year.
The final result should be sorted in ascending order based on three criteria: first by 'country_region,'
then by 'calendar_year,' and finally by 'channel_desc'
*/

WITH total_sales_rc AS ( -- getting totat amount FOR region_channel BY year
SELECT
	t.calendar_year,
	c2.country_region,
	s.channel_id,
	ch.channel_desc,
	SUM(s.amount_sold) AS amount_sold
FROM
	sh.sales s
JOIN sh.times t ON
	t.time_id = s.time_id
JOIN sh.customers cu ON
	cu.cust_id = s.cust_id
JOIN sh.countries c2 ON
	c2.country_id = cu.country_id
JOIN sh.channels ch ON
	ch.channel_id = s.channel_id
WHERE
	LOWER(c2.country_region) IN ('americas', 'asia', 'europe')
GROUP BY
	t.calendar_year,
	c2.country_region,
	s.channel_id,
	ch.channel_desc
),
total_sales_ry AS ( -- getting totat amount FOR region BY year
SELECT
	calendar_year,
	country_region,
	SUM(amount_sold) AS total_amount_year_region
FROM
	total_sales_rc
GROUP BY
	calendar_year,
	country_region
),
current_percent AS ( -- getting PERCENT FOR CURRENT YEAR
SELECT
	ts.calendar_year,
	ts.country_region,
	ts.channel_id,
	ts.channel_desc,
	ts.amount_sold,
	ts.amount_sold / tsy.total_amount_year_region * 100 AS percent_by_channel
FROM
	total_sales_rc ts
JOIN total_sales_ry tsy
    ON
	ts.calendar_year = tsy.calendar_year
	AND ts.country_region = tsy.country_region),
with_previous_percent AS (-- getting PERCENT FOR previous YEAR
SELECT
	calendar_year,
	country_region,
	channel_desc,
	amount_sold,
	percent_by_channel,
	CASE
		WHEN calendar_year - LAG(calendar_year) OVER (
                PARTITION BY country_region,
		channel_desc
	ORDER BY
		calendar_year RANGE BETWEEN 1 PRECEDING AND 1 PRECEDING
            ) = 1 THEN LAG(percent_by_channel) OVER (
                PARTITION BY country_region,
		channel_desc
	ORDER BY
		calendar_year
            )
		ELSE NULL
	END AS percent_previous_period
FROM
	current_percent
)
SELECT
	country_region,
	calendar_year ,
	channel_desc,
	to_char(amount_sold, '999,999,999.99') AS amount_sold,
	to_char(percent_by_channel, '999.99 %') AS "% BY CHANNELS",
	to_char(percent_previous_period, '999.99 %') AS "% PREVIOUS PERIOD",
	to_char(percent_by_channel - percent_previous_period, '999.99 %') AS "% DIFF"
FROM
	with_previous_percent
WHERE
	calendar_year BETWEEN 1999 AND 2001
ORDER BY
	country_region,
	calendar_year,
	channel_desc;

/* TASK 2
You need to create a query that meets the following requirements:
Generate a sales report for the 49th, 50th, and 51st weeks of 1999.
Include a column named CUM_SUM to display the amounts accumulated during each week.
Include a column named CENTERED_3_DAY_AVG to show the average sales for the previous,
 current, and following days using a centered moving average.
For Monday, calculate the average sales based on the weekend sales
(Saturday and Sunday) as well as Monday and Tuesday.
For Friday, calculate the average sales on Thursday, Friday, and the weekend.


Ensure that your calculations are accurate for the beginning of week 49 and the end of week 51.

 */
--report fully excluded other weeks
WITH datas_for_report AS ( --getting DATA FROM FOLLOWING calculation
SELECT
	t.calendar_week_number,
	t.time_id,
	t.day_name,
	sum(s.amount_sold) AS day_amount_sold
FROM
	sh.sales s
JOIN sh.times t ON
	t.time_id = s.time_id
WHERE
	t.calendar_week_number BETWEEN 49 AND 51
	AND t.calendar_year = 1999
GROUP BY
	t.calendar_week_number,
	t.time_id,
	t.day_name),
report_calculation AS ( --calculating
SELECT
	calendar_week_number,
	time_id,
	day_name,
	day_amount_sold,
	sum(day_amount_sold) OVER (PARTITION BY calendar_week_number
ORDER BY
	time_id RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_sum,
	CASE
		WHEN LOWER(day_name) = 'monday' THEN
                AVG(day_amount_sold) OVER (
	ORDER BY
		time_id
                    RANGE BETWEEN INTERVAL '2 days' PRECEDING AND INTERVAL '1 day' FOLLOWING
                )
		WHEN LOWER(day_name) = 'friday' THEN
                AVG(day_amount_sold) OVER (
	ORDER BY
		time_id
                    RANGE BETWEEN INTERVAL '1 day' PRECEDING AND INTERVAL '2 days' FOLLOWING
                )
		ELSE AVG(day_amount_sold) OVER (
	ORDER BY
		time_id
                    RANGE BETWEEN INTERVAL '1 day' PRECEDING AND INTERVAL '1 day' FOLLOWING
                )
	END AS CENTERED_3_DAY_AVG
FROM
	datas_for_report)
SELECT
	calendar_week_number,
	time_id,
	day_name,
	to_char(day_amount_sold,
	'999,999,999.99') AS day_amount_sold,
	to_char(cum_sum,
	'999,999,999.99') AS cum_sum,
	to_char(CENTERED_3_DAY_AVG,
	'999,999,999.99') AS CENTERED_3_DAY_AVG
FROM
	report_calculation;

--report with data included 48 and 51 weeks
WITH datas_for_report AS (
SELECT
	t.calendar_week_number,
	t.time_id,
	t.day_name,
	sum(s.amount_sold) AS day_amount_sold
FROM
	sh.sales s
JOIN sh.times t ON
	t.time_id = s.time_id
WHERE
	t.calendar_week_number BETWEEN 48 AND 52
	AND t.calendar_year = 1999
GROUP BY
	t.calendar_week_number,
	t.time_id,
	t.day_name),
report_calculation AS (
SELECT
	calendar_week_number,
	time_id,
	day_name,
	day_amount_sold,
	sum(day_amount_sold) OVER (PARTITION BY calendar_week_number
ORDER BY
	time_id RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_sum,
	CASE
		WHEN LOWER(day_name) = 'monday' THEN
                AVG(day_amount_sold) OVER (
	ORDER BY
		time_id
                    RANGE BETWEEN INTERVAL '2 days' PRECEDING AND INTERVAL '1 day' FOLLOWING
                )
		WHEN LOWER(day_name) = 'friday' THEN
                AVG(day_amount_sold) OVER (
	ORDER BY
		time_id
                    RANGE BETWEEN INTERVAL '1 day' PRECEDING AND INTERVAL '2 days' FOLLOWING
                )
		ELSE AVG(day_amount_sold) OVER (
	ORDER BY
		time_id
                    RANGE BETWEEN INTERVAL '1 day' PRECEDING AND INTERVAL '1 day' FOLLOWING
                )
	END AS CENTERED_3_DAY_AVG
FROM
	datas_for_report)
SELECT
	calendar_week_number,
	time_id,
	day_name,
	to_char(day_amount_sold,
	'999,999,999.99') AS day_amount_sold,
	to_char(cum_sum,
	'999,999,999.99') AS cum_sum,
	to_char(CENTERED_3_DAY_AVG,
	'999,999,999.99') AS CENTERED_3_DAY_AVG
FROM
	report_calculation
WHERE
	calendar_week_number BETWEEN 49 AND 51;


/*TASK3
Please provide 3 instances of utilizing window functions that include a frame clause, using RANGE, ROWS, and GROUPS modes.
Additionally, explain the reason for choosing a specific frame type for each example.
This can be presented as a single query or as three distinct queries

 */
--RANGE mode is ideal when working with ranges of values, such as prices or dates,
-- so we can get datas in range of values we need, not by rows.
SELECT
	prod_id,
	prod_list_price,
	prod_category,
	AVG(prod_list_price) OVER (
            PARTITION BY prod_category
ORDER BY
	prod_list_price
            RANGE BETWEEN 10 PRECEDING AND 10 FOLLOWING
        ) AS avg_price_in_range
FROM
	sh.products
ORDER BY prod_category , prod_list_price ;

--ROWS mode is used when you need to consider a fixed number of rows.
SELECT
	time_id,
	quantity_sold,
	SUM(quantity_sold) OVER (
            PARTITION BY channel_id
ORDER BY
	time_id
            ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING
        ) AS row5_sum
FROM
	sh.sales;

--GROUPS is a frame type that groups rows based on the equality of the ORDER BY clause values.
--Here groups to get sums of different groups based on month here so we can compare current group and previous
SELECT
    t.calendar_month_number,
    SUM(amount_sold) AS m_sales,
    FIRST_VALUE(SUM(amount_sold)) OVER (
        ORDER BY t.calendar_month_number
        GROUPS BETWEEN 1 PRECEDING AND CURRENT ROW
    ) AS groups_first_value
FROM
    sh.sales s
JOIN
    sh.customers c ON c.cust_id = s.cust_id
JOIN
    sh.times t ON t.time_id = s.time_id
JOIN
    sh.channels ch ON ch.channel_id = s.channel_id
WHERE
    t.calendar_year = 1998
    AND ch.channel_desc = 'Tele Sales'
GROUP BY
    t.calendar_month_number
ORDER BY
    t.calendar_month_number;
