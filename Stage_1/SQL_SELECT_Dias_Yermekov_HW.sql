-- TASK: All animation movies released between 2017 and 2019 with rate more than 1, alphabetical
/*The query filters films categorized as "Animation" that were released between the years 2017 and 2019 and have a rental rate exceeding 1.
  This likely supports a report or analysis on recent high-rental-rate animation movies.
*/
SELECT
	f.title,
	f.release_year,
	f.rental_rate,
	c.name
FROM
	public.film f
LEFT JOIN public.film_category fc ON
	f.film_id = fc.film_id
LEFT JOIN public.category c ON
	fc.category_id = c.category_id
WHERE
	lower(c.name) = 'animation'
	AND f.release_year BETWEEN 2017 AND 2019
	AND f.rental_rate > 1
ORDER BY
	f.title ASC;

--CTE
WITH filtered_films AS (
    SELECT
        f.title,
        f.release_year,
        f.rental_rate,
        c.name
    FROM
        public.film f
    LEFT JOIN public.film_category fc ON
        f.film_id = fc.film_id
    LEFT JOIN public.category c ON
        fc.category_id = c.category_id
    WHERE
        c.name = 'Animation'
        AND f.release_year BETWEEN 2017 AND 2019
        AND f.rental_rate > 1
)
SELECT
    title,
    release_year,
    rental_rate,
    name
FROM
    filtered_films
ORDER BY title ASC;


--TASK: The revenue earned by each rental store since March 2017 (columns: address and address2 – as one column, revenue)

--This query calculates the total revenue for each rental store since March 2017,
--outputting it with a full address column to facilitate store-specific financial reporting.

SELECT
	s.store_id,
	COALESCE(a.address, '') || ' ' || COALESCE(a.address2, '') AS full_address,
	SUM(p.amount) AS revenue
FROM
	public.address a
LEFT JOIN
    public.store s ON
	a.address_id = s.address_id
LEFT JOIN
    public.inventory i ON
	i.store_id = s.store_id
LEFT JOIN
    public.rental r ON
	r.inventory_id = i.inventory_id
LEFT JOIN
    public.payment p ON
	p.rental_id = r.rental_id
WHERE
	p.payment_date >= '2017-03-01'
GROUP BY
	 s.store_id, full_address
;

--CTE
WITH store_revenue AS (
SELECT
	s.store_id,
	COALESCE(a.address, '') || ' ' || COALESCE(a.address2, '') AS full_address,
	p.amount,
	p.payment_date
FROM
	public.address a
LEFT JOIN public.store s ON
	a.address_id = s.address_id
LEFT JOIN public.inventory i ON
	i.store_id = s.store_id
LEFT JOIN public.rental r ON
	r.inventory_id = i.inventory_id
LEFT JOIN public.payment p ON
	p.rental_id = r.rental_id
)
SELECT
	store_id,
	full_address,
	SUM(amount) AS revenue
FROM
	store_revenue
WHERE
	payment_date >= '2017-03-01'
GROUP BY
	store_id, full_address;

/* TASK: Top-5 actors by number of movies (released since 2015) they took part in (columns: first_name, last_name, number_of_movies,
sorted by number_of_movies in descending order)*/

-- This query identifies the top actors based on their activity level since 2015, which may support casting or performance evaluation insights.

SELECT
	a.first_name,
	a.last_name,
	count(a.actor_id) AS number_of_movies
FROM
	public.actor a
LEFT JOIN public.film_actor fa ON
	fa.actor_id = a.actor_id
LEFT JOIN public.film f ON
	f.film_id = fa.film_id
WHERE
	f.release_year >= 2015
GROUP BY
	a.actor_id
ORDER BY
	number_of_movies DESC
LIMIT 5;


/* TASK: Number of Drama, Travel, Documentary per year (columns: release_year, number_of_drama_movies, number_of_travel_movies, number_of_documentary_movies),
sorted by release year in descending order. Dealing with NULL values is encouraged)*/

-- This query helps track the release trends of specific genres over time, likely for market or content distribution analysis.

SELECT
	f.release_year,
	count(CASE WHEN c.name = 'Drama' THEN 1 END) AS number_of_documentary_movies,
	count(CASE WHEN c.name = 'Travel' THEN 1 END) AS number_of_travel_movies,
	count(CASE WHEN c.name = 'Documentary' THEN 1 END) AS number_of_documentary_movies
FROM
	public.film f
LEFT JOIN public.film_category fc ON
	fc.film_id = f.film_id
LEFT JOIN public.category c ON
	c.category_id = fc.category_id
WHERE
	LOWER(c.name) IN ('documentary', 'drama', 'travel')
GROUP BY
	f.release_year
ORDER BY
	f.release_year DESC;

/*

TASK: For each client, display a list of horrors that he had ever rented (in one column, separated by commas), and the amount of money that he paid for it*/
--This query provides a client-specific summary of rented horror movies, along with the total payments,
--useful for customer insights or rental behavior analysis.

SELECT c.customer_id ,
	c.first_name || ' ' || c.last_name AS client_full_name,
	STRING_AGG(DISTINCT f.title::TEXT, ', '),
	sum(p.amount) AS total_paid
FROM
	public.customer c
LEFT JOIN public.rental r ON
	r.customer_id = c.customer_id
LEFT JOIN public.inventory i ON
	r.inventory_id = i.inventory_id
LEFT JOIN public.film f ON
	f.film_id = i.film_id
LEFT JOIN public.film_category fc ON
	f.film_id = fc.film_id
LEFT JOIN public.category ct ON
	ct.category_id = fc.category_id
LEFT JOIN public.payment p ON
	p.customer_id = c.customer_id
WHERE
	LOWER(ct.name) = 'horror'
GROUP BY
	c.customer_id;

/*
TASK: 1. Which three employees generated the most revenue in 2017? They should be awarded a bonus for their outstanding performance.
Assumptions:
staff could work in several stores in a year, please indicate which store the staff worked in (the last one);
if staff processed the payment then he works in the same store;
take into account only payment_date
 */

--This query retrieves the top rented films and provides an age-appropriate rating description for each one,
--using the Motion Picture Association film rating system.
SELECT
	s.first_name,
	s.last_name,
	SUM(p.amount) AS total_revenue,
	s.store_id AS last_store_worked_in
FROM
	public.staff s
JOIN
    public.payment p ON
	p.staff_id = s.staff_id
WHERE
	EXTRACT(YEAR FROM	p.payment_date) = 2017
GROUP BY
	s.staff_id,
	s.first_name,
	s.last_name,
	s.store_id
ORDER BY
	total_revenue DESC
LIMIT 3;



/*

TASK: Which 5 movies were rented more than others (number of rentals), and what's the expected age of the audience for these movies?
 To determine expected age please use 'Motion Picture Association film rating system
*/
--This query counts how many times each film has been rented and assigns an audience guidance description based on its rating,
--allowing for the identification of popular films and appropriate viewer age.

SELECT
	f.film_id,
	f.title,
	count(f.film_id) AS rented_times,
	CASE
		WHEN f.rating = 'G' THEN 'General audiences – All ages admitted.'
		WHEN f.rating = 'PG' THEN 'Parental guidance suggested – Some material may not be suitable for children.'
		WHEN f.rating = 'PG-13' THEN 'Parents strongly cautioned – Some material may be inappropriate for children under 13.'
		WHEN f.rating = 'R' THEN 'Restricted – Under 17 requires accompanying parent or adult guardian.'
		ELSE 'Adults only – No one 17 and under admitted.'
	END AS expected_age
FROM
	public.film f
LEFT JOIN public.inventory i ON
	i.film_id = f.film_id
LEFT JOIN public.rental r ON
	r.inventory_id = i.inventory_id
GROUP BY
	f.film_id,
	f.title
ORDER BY
	rented_times DESC
LIMIT 5;


/*
Part 3. Which actors/actresses didn't act for a longer period of time than the others?

The task can be interpreted in various ways, and here are a few options:
V1: gap between the latest release_year and current year per each actor;
*/

/*
This query finds the time gap between each actor's last appearance in a film and the current year,
providing a way to identify actors who have been inactive for the longest time.
*/
WITH latest_film AS (
SELECT
	fa.actor_id,
	MAX(f.release_year) AS latest_active
FROM
	public.film_actor fa
INNER JOIN public.film f ON
	f.film_id = fa.film_id
GROUP BY
	fa.actor_id
)
SELECT
	a.actor_id,
	a.first_name,
	a.last_name,
	EXTRACT(YEAR FROM now()) - la.latest_active AS inactive_period,
	la.latest_active
FROM
	public.actor a
INNER JOIN latest_film la ON
	la.actor_id = a.actor_id
GROUP BY
	a.actor_id,
	a.last_name,
	a.first_name,
	la.latest_active
ORDER BY
	inactive_period DESC ;

--V2: gaps between sequential films per each actor;

--No solution
