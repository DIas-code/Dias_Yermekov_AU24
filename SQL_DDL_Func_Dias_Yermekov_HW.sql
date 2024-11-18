--Task 1. Create a view
--Create a view called 'sales_revenue_by_category_qtr' that shows the film category and total sales revenue for the current quarter and year. 
--The view should only display categories with at least one sale in the current quarter. 
--Note: when the next quarter begins, it will be considered as the current quarter.

CREATE OR REPLACE
VIEW public.sales_revenue_by_category_qtr AS 
SELECT
	c.name,
	sum(p.amount) AS total_payment,
	EXTRACT(quarter
FROM
	now()) AS current_quarter,
	EXTRACT(YEAR
FROM
	now()) AS current_year
FROM
	public.category c
JOIN public.film_category fc ON
	fc.category_id = c.category_id
JOIN public.film f ON
	f.film_id = fc.film_id
JOIN public.inventory i ON
	i.film_id = f.film_id
JOIN public.rental r ON
	r.inventory_id = i.inventory_id
JOIN public.payment p ON
	p.rental_id = r.rental_id
WHERE
	EXTRACT(QUARTER
FROM
	p.payment_date) = EXTRACT(QUARTER
FROM
	now())
	AND EXTRACT(YEAR
FROM
	p.payment_date) = EXTRACT(YEAR
FROM
	now())
GROUP BY
	c.name
HAVING
	SUM(p.amount) > 0;
SELECT * FROM public.sales_revenue_by_category_qtr;
DROP VIEW IF EXISTS public.sales_revenue_by_category_qtr;
SELECT * FROM payment p ORDER BY payment_id desc;
--SELECT * FROM rental r ;


--Task 2. Create a query language functions
--Create a query language function called 'get_sales_revenue_by_category_qtr' that accepts one parameter 
--representing the current quarter and year and returns the same result as the 'sales_revenue_by_category_qtr' view.

CREATE OR REPLACE FUNCTION public.sales_revenue_by_category_qtr_func(
    payment_quarter INT,
    payment_year INT
)
RETURNS TABLE (
    category_name TEXT,
    total_payment DECIMAL,
    p_quarter INT,
    p_year INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.name AS category_name,
        SUM(p.amount) AS total_payment,
        payment_quarter AS p_quarter,
        payment_year AS p_year
    FROM
        public.category c
    JOIN public.film_category fc ON
        fc.category_id = c.category_id
    JOIN public.film f ON
        f.film_id = fc.film_id
    JOIN public.inventory i ON
        i.film_id = f.film_id
    JOIN public.rental r ON
        r.inventory_id = i.inventory_id
    JOIN public.payment p ON
        p.rental_id = r.rental_id
    WHERE
        EXTRACT(QUARTER FROM p.payment_date) = payment_quarter
        AND EXTRACT(YEAR FROM p.payment_date) = payment_year
    GROUP BY
        c.name
    HAVING
        SUM(p.amount) > 0;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM public.sales_revenue_by_category_qtr_func(1, 2017);

--Task 3. Create procedure language functions
--Create a function that takes a country as an input parameter and returns the most popular film in that specific country. 
--The function should format the result set as follows:
--Query (example):select * from core.most_popular_films_by_countries(array['Afghanistan','Brazil','United States’]);
CREATE OR REPLACE
FUNCTION public.most_popular_films_by_countries(countries TEXT[])
RETURNS TABLE(
    country TEXT,
    title TEXT,
    rating public."mpaa_rating",
    "language" bpchar(20),
    "length" int2,
    release_year public."year",
    rental_cnt BIGINT
) AS 
$$
DECLARE 
    country_name TEXT;

BEGIN 
    FOREACH country_name IN ARRAY countries LOOP
        RETURN QUERY 
        SELECT
	cut.country AS country,
	f.title AS title,
	f.rating AS rating,
	l."name" AS "language",
	f."length" AS "length",
	f.release_year AS release_year,
	COUNT(r.rental_id) AS rental_cnt
FROM
	public.film f
JOIN public.inventory i ON
	i.film_id = f.film_id
JOIN public.rental r ON
	r.inventory_id = i.inventory_id
JOIN public.customer c ON
	c.customer_id = r.customer_id
JOIN public.address a ON
	c.address_id = a.address_id
JOIN public.city ct ON
	ct.city_id = a.city_id
JOIN public.country cut ON
	cut.country_id = ct.city_id
JOIN public.language l ON
	l.language_id = f.language_id
WHERE
	lower(cut.country) = lower(country_name)
GROUP BY
	cut.country,
	f.title,
	f.rating,
	l."name",
	f."length",
	f.release_year
ORDER BY
	COUNT(r.rental_id) DESC
		FETCH NEXT 1 ROW WITH TIES ;
END LOOP;

RETURN;
END;

$$ LANGUAGE plpgsql;

SELECT * FROM public.most_popular_films_by_countries(ARRAY['Romania', 'Brazil', 'United States']);

DROP FUNCTION public.most_popular_films_by_countries(text[]);

--Task 4. Create procedure language functions
--Create a function that generates a list of movies available in stock based on a 
--partial title match (e.g., movies containing the word 'love' in their title). 
--The titles of these movies are formatted as '%...%', and if a movie with the specified title is not in stock, 
--return a message indicating that it was not found.
--The function should produce the result set in the following format 
--(note: the 'row_num' field is an automatically generated counter field, 
--starting from 1 and incrementing for each entry, e.g., 1, 2, ..., 100, 101, ...).
--
--                    Query (example):select * from core.films_in_stock_by_title('%love%’);
	
CREATE OR REPLACE FUNCTION public.films_in_stock_by_title(part_of_title TEXT)
RETURNS TABLE (
    row_num BIGINT,
    title TEXT,
    "language" bpchar(20),
    customer_name TEXT,
    rental_date TIMESTAMPTZ
) AS 
$$
DECLARE
    result_count INT;
BEGIN
	SELECT COUNT(*)
    INTO result_count
    FROM (
        WITH max_rentals AS (
            SELECT 
                f.film_id,
                f.title,
                l."name" AS "language",
                MAX(r.rental_date) AS max_rental_date
            FROM 
                public.film f 
            JOIN 
                public."language" l ON l.language_id = f.language_id
            JOIN 
                public.inventory i ON f.film_id = i.film_id
            JOIN 
                public.rental r ON r.inventory_id = i.inventory_id
            WHERE 
                lower(f.title) LIKE lower(part_of_title)
            GROUP BY 
                f.film_id, f.title, l."name"
        )
        SELECT 
            m.title,
            m.language,
            c.first_name AS customer_name,
            m.max_rental_date AS rental_date
        FROM 
            max_rentals m
        JOIN 
            public.inventory i ON m.film_id = i.film_id
        JOIN 
            public.rental r ON r.inventory_id = i.inventory_id
        JOIN 
            public.customer c ON r.customer_id = c.customer_id
        WHERE 
            r.rental_date = m.max_rental_date
    ) AS subquery;

    IF result_count = 0 THEN
        RAISE NOTICE 'Not in stock';
    END IF;
    RETURN QUERY 
    WITH max_rentals AS (
        SELECT 
            f.film_id,
            f.title,
            l."name" AS "language",
            MAX(r.rental_date) AS max_rental_date
        FROM 
            public.film f 
        JOIN 
            public."language" l ON l.language_id = f.language_id
        JOIN 
            public.inventory i ON f.film_id = i.film_id
        JOIN 
            public.rental r ON r.inventory_id = i.inventory_id
        WHERE 
            lower(f.title) LIKE lower(part_of_title)
        GROUP BY 
            f.film_id, f.title, l."name"
    )
    SELECT 
        ROW_NUMBER() OVER () AS row_num,
        m.title,
        m.language,
        c.first_name AS customer_name,
        m.max_rental_date AS rental_date
    FROM 
        max_rentals m
    JOIN 
        public.inventory i ON m.film_id = i.film_id
    JOIN 
        public.rental r ON r.inventory_id = i.inventory_id
    JOIN 
        public.customer c ON r.customer_id = c.customer_id
    WHERE 
        r.rental_date = m.max_rental_date
    ORDER BY 
        m.title;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM public.films_in_stock_by_title('%love%');

DROP FUNCTION films_in_stock_by_title(text);

--Task 5. Create procedure language functions
--Create a procedure language function called 'new_movie' that takes a movie title as a parameter and inserts a 
--new movie with the given title in the film table. The function should generate a new unique film ID, set the rental rate to 4.99, 
--the rental duration to three days, the replacement cost to 19.99. The release year and language are optional 
--and by default should be current year and Klingon respectively. 
--The function should also verify that the language exists in the 'language' table. 
--Then, ensure that no such function has been created before; if so, replace it.

CREATE OR REPLACE FUNCTION new_movie(
    movie_title TEXT,
    release_year INT DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)::INT,
    lang_name TEXT DEFAULT 'Klingon'
) RETURNS VOID AS 
$$
$$
LANGUAGE plpgsql;

--SELECT actor_id, first_name, last_name, last_update
--FROM public.actor;
--SELECT address_id, address, address2, district, city_id, postal_code, phone, last_update
--FROM public.address;
--SELECT category_id, "name", last_update
--FROM public.category;
--SELECT city_id, city, country_id, last_update
--FROM public.city;
--SELECT country_id, country, last_update
--FROM public.country;
--SELECT customer_id, store_id, first_name, last_name, email, address_id, activebool, create_date, last_update, active
--FROM public.customer;
--SELECT film_id, title, description, release_year, language_id, original_language_id, rental_duration, rental_rate, length, replacement_cost, rating, last_update, special_features, fulltext
--FROM public.film;
--SELECT actor_id, film_id, last_update
--FROM public.film_actor;
--SELECT film_id, category_id, last_update
--FROM public.film_category;
--SELECT inventory_id, film_id, store_id, last_update
--FROM public.inventory;
--SELECT language_id, "name", last_update
--FROM public."language";
--SELECT payment_id, customer_id, staff_id, rental_id, amount, payment_date
--FROM public.payment;
--SELECT rental_id, rental_date, inventory_id, customer_id, return_date, staff_id, last_update
--FROM public.rental;
--SELECT staff_id, first_name, last_name, address_id, email, store_id, active, username, "password", last_update, picture
--FROM public.staff;
--SELECT store_id, manager_staff_id, address_id, last_update
--FROM public.store;
