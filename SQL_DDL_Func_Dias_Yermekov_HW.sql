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
	given_date date
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
        EXTRACT(QUARTER FROM given_date)::INT AS p_quarter,
        EXTRACT(YEAR FROM given_date)::INT AS p_year
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
        EXTRACT(QUARTER FROM p.payment_date) = EXTRACT(QUARTER FROM given_date)
        AND EXTRACT(YEAR FROM p.payment_date) = EXTRACT(YEAR FROM given_date)
    GROUP BY
        c.name
    HAVING
        SUM(p.amount) > 0;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM public.sales_revenue_by_category_qtr_func('2017-01-01');


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
    cut.country as country,
    f.title AS title,
    f.rating AS rating,
    l."name" AS "language",
    f."length" AS "length",
    f.release_year AS release_year,
    COUNT(r.rental_id) AS rental_cnt
FROM
    public.country cut
JOIN public.city ct ON
    ct.country_id = cut.country_id
JOIN public.address a ON
    a.city_id = ct.city_id
JOIN public.customer c ON
    c.address_id = a.address_id
LEFT JOIN public.rental r ON
    r.customer_id = c.customer_id
LEFT JOIN public.inventory i ON
    r.inventory_id = i.inventory_id
LEFT JOIN public.film f ON
    f.film_id = i.film_id
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

SELECT * FROM public.most_popular_films_by_countries(ARRAY['Canada', 'Brazil', 'United States']);

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
    row_num INT,
    title TEXT,
    "language" bpchar(20),
    customer_name TEXT,
    rental_date TIMESTAMPTZ
) AS 
$$
DECLARE
    movie_counter INT := 0;
    rec RECORD;
BEGIN
    FOR rec IN
		WITH max_rentals AS (
            SELECT 
                f.film_id,
                f.title,
                l."name" AS "language",
                MAX(r.rental_date) AS max_rental_date
            FROM 
                public.film f 
            left JOIN 
                public."language" l ON l.language_id = f.language_id
            left JOIN 
                public.inventory i ON f.film_id = i.film_id
            left JOIN 
                public.rental r ON r.inventory_id = i.inventory_id
            WHERE 
                lower(f.title) LIKE lower(part_of_title)
            GROUP BY 
                f.film_id, f.title, l."name"
        ) -- cte for uniqu title
        SELECT 
            f.title AS title,
            l."name" AS "language",
            c.first_name AS customer_name,
            r.rental_date
        FROM 
            public.film f
        LEFT JOIN 
            public."language" l USING(language_id)
        LEFT JOIN 
            public.inventory i ON i.film_id = f.film_id
        LEFT JOIN 
            public.rental r ON r.inventory_id = i.inventory_id
        LEFT JOIN 
            customer c ON c.customer_id = r.customer_id
        WHERE 
            lower(f.title) LIKE lower(part_of_title)
            AND (r.rental_date IS NULL OR r.return_date IS NOT NULL)
			AND r.rental_date = (SELECT max_rental_date FROM max_rentals mr 
				WHERE mr.title = f.title) -- for unique title, 
--			AND (SELECT max_rental_date FROM max_rentals mr WHERE mr.title = f.title) IS NOT NULL)
--                OR (SELECT max_rental_date FROM max_rentals mr WHERE mr.title = f.title) IS NULL)
        ORDER BY 
            f.title
    LOOP
        movie_counter := movie_counter + 1;
        row_num := movie_counter;
        title := rec.title;
        "language" := rec.language;
        customer_name := rec.customer_name;
        rental_date := rec.rental_date;
        RETURN NEXT;
    END LOOP;

    IF NOT FOUND THEN 
        RAISE NOTICE 'Not in stock';
    END IF;
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
    new_title text,
    new_release_year public."year" DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)::public."year",
    new_language bpchar(20) DEFAULT 'Klingon'
) RETURNS VOID AS $$
DECLARE
    new_language_id INT2;
BEGIN
    -- Check if the language exists
    SELECT l.language_id INTO new_language_id
    FROM public."language" l 
    WHERE l.name = new_language;

    IF new_language_id IS NULL THEN
        RAISE EXCEPTION 'Language "%" does not exist in the language table', new_language;
    END IF;

-- checking for existing title
    IF EXISTS (
        SELECT 1
        FROM public.film
        WHERE title = new_title
    ) THEN
        RAISE EXCEPTION 'Movie "%" already exists in the film table', new_title;
    END IF;

    -- Inserting
    INSERT INTO public.film (title, release_year, rental_rate, rental_duration, replacement_cost, language_id)
    SELECT
        new_title,
        new_release_year,
        4.99,
        3,
        19.99,
        new_language_id;
END;
$$ LANGUAGE plpgsql;

SELECT new_movie('GTMax', 2024 ,'English');
SELECT * FROM public.film f ORDER BY film_id DESC;

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
