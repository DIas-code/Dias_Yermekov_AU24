/*
 Choose your top-3 favorite movies and add them to the 'film' table 
 (films with the title Film1, Film2, etc - will not be taken into account and grade will be reduced)
Fill in rental rates with 4.99, 9.99 and 19.99 and rental durations with 1, 2 and 3 weeks respectively.

 */

--CTE for defining first 2 tasks, mainly films title, rental rates, rental duration with some additional information like year, description etc.
WITH new_movies AS (
	SELECT 
		'Green Book' AS title,
		'A working-class Italian-American bouncer becomes the driver for ' ||
		'an African-American classical pianist on a tour of venues through ' || 
		'the 1960s American South1.' AS description,
		2005 AS release_year,
		(
		SELECT
			l.language_id
		FROM
			public."language" l
		WHERE
			lower( l."name") = 'english') AS language_id,
		7 AS rental_duration,
		4.99 AS rental_rate,
		130 AS length,
		'R'::mpaa_rating AS rating
	UNION ALL 
	SELECT 
		'The Chronicles of Narnia: The Lion, the Witch and the Wardrobe' AS title,
		'While playing, Lucy and her siblings find a wardrobe that lands them in a mystical place called Narnia.' || 
		'Here they realize that it was fated and they must now unite with Aslan to defeat an evil queen.' AS description,
		2018 AS release_year,
		(
		SELECT
			l.language_id
		FROM
			public."language" l
		WHERE
			lower( l."name") = 'english') AS language_id,
		14 AS rental_duration,
		9.99 AS rental_rate,
		143 AS length,
		'PG'::mpaa_rating AS rating
	UNION ALL 
	SELECT 
		'Original title: The Golden Compass' AS title,
		'In a parallel universe, young Lyra Belacqua journeys to the far North to save her best friend and other ' || 
		'kidnapped children from terrible experiments by a mysterious organization.' AS description,
		2007 AS release_year,
		(
		SELECT
			l.language_id
		FROM
			public."language" l
		WHERE
			lower( l."name") = 'english') AS language_id,
		21 AS rental_duration,
		19.99 AS rental_rate,
		113 AS length,
		'PG-13'::mpaa_rating AS rating
), --CTE FOR inserting movies that defined in previous CTE with checking on existing in database
inserted_movies AS (
	INSERT INTO public.film 
		(title,
		description,
		release_year,
		language_id,
		rental_duration,
		rental_rate,
		"length",
		rating,
		last_update) 
	SELECT
		nm.title,
		nm.description,
		nm.release_year,
		nm.language_id,
		nm.rental_duration,
		nm.rental_rate,
		nm."length",
		nm.rating,
		current_date AS last_update
	FROM
		new_movies nm
	WHERE 
		NOT EXISTS (SELECT 
						* 
					FROM 
						public.film f
					WHERE 
						f.title = nm.title AND
						f.release_year = nm.release_year)
	RETURNING film_id, title, release_year, rental_duration, rental_rate, last_update
)
SELECT film_id, title, release_year, rental_duration, rental_rate, last_update FROM inserted_movies
;

/*Add the actors who play leading roles in your favorite movies to the 'actor' and 'film_actor' tables (6 or more actors in total).  
Actors with the name Actor1, Actor2, etc - will not be taken into account and grade will be reduced.*/

--CTE for defining actors first and last name, also defined titles in which they participated for getting film_id while inserting into film_actor table.
WITH new_actors AS (
    SELECT 
        'Viggo2' AS first_name,
        'Mortensen2' AS last_name,
        'Green Book' AS title
    UNION ALL 
    SELECT
        'Mahershala' AS first_name,
        'Ali' AS last_name,
        'Green Book' AS title
    UNION ALL 
    SELECT
        'Linda' AS first_name,
        'Cardellini' AS last_name,
        'Green Book' AS title
    UNION ALL 
    SELECT
        'Tilda' AS first_name,
        'Swinton' AS last_name,
        'The Chronicles of Narnia: The Lion, the Witch and the Wardrobe' AS title
    UNION ALL 
    SELECT
        'Georgie' AS first_name,
        'Henley' AS last_name,
        'The Chronicles of Narnia: The Lion, the Witch and the Wardrobe' AS title
    UNION ALL 
    SELECT
        'William' AS first_name,
        'Moseley' AS last_name,
        'The Chronicles of Narnia: The Lion, the Witch and the Wardrobe' AS title
    UNION ALL 
    SELECT
        'Nicole' AS first_name,
        'Kidman' AS last_name,
        'Original title: The Golden Compass' AS title
    UNION ALL 
    SELECT
        'Daniel' AS first_name,
        'Craig' AS last_name,
        'Original title: The Golden Compass' AS title
    UNION ALL 
    SELECT
        'Dakota' AS first_name,
        'Blue Richards' AS last_name,
        'Original title: The Golden Compass' AS title
), --CTE FOR inserting DATA without duplicates INTO actor TABLE.
inserted_actors AS (
    INSERT INTO public.actor (first_name, last_name, last_update) 
    SELECT first_name, last_name, current_date
    FROM new_actors na
    WHERE NOT EXISTS (
        SELECT 1 
        FROM public.actor a
        WHERE a.first_name = na.first_name 
          AND a.last_name = na.last_name
    )
    RETURNING actor_id, first_name, last_name
), --CTE FOR inserting actors AND films INTO film_actor TABLE WITHOUT duplicates
inserted_film_actors AS (
    INSERT INTO public.film_actor (actor_id, film_id, last_update)
    SELECT ia.actor_id, f.film_id, current_date AS last_update
    FROM inserted_actors ia
    JOIN new_actors na ON 
        na.first_name = ia.first_name AND na.last_name = ia.last_name
    JOIN public.film f ON 
        na.title = f.title
    ON CONFLICT (actor_id, film_id) DO NOTHING 
    RETURNING actor_id, film_id, last_update
)
SELECT 
    iaf.film_id, 
    iaf.actor_id, 
    ia.first_name, 
    ia.last_name,
    f.title,
    iaf.last_update
FROM inserted_film_actors iaf
JOIN inserted_actors ia ON ia.actor_id = iaf.actor_id
JOIN film f ON iaf.film_id = f.film_id; 
SELECT * FROM film_actor fa ;
--CTE that inserts film_id and store_id into inventory without checking it on duplicates, 
-- because any store can have more than one copy of film.
-- This method more harder to re-use, but for a single insert with a small number of inserted movies it is fast, 
--I decided to use the quick method 
WITH inserting_film_to_inventory AS (
	INSERT INTO inventory 	
		(film_id,
		 store_id,
		 last_update)
	SELECT
		f.film_id,
		1 AS store_id,
		CURRENT_DATE
	FROM
		public.film f
	WHERE
		lower(f.title) = 'original title: the golden compass' OR		
		lower(f.title) = 'green book' OR 	
		lower(f.title) = 'the chronicles of narnia: the lion, the witch and the wardrobe'
	RETURNING inventory_id, film_id, store_id 
)
SELECT inventory_id, film_id, store_id FROM inserting_film_to_inventory ;
SELECT * FROM inventory i ;
SELECT current_date;

--Alter any existing customer in the database with at least 43 rental and 43 payment records. 
--Change their personal data to yours (first name, last name, address, etc.). 
--You can use any existing address from the "address" table. 
--Please do not perform any updates on the "address" table, as this can impact multiple records with the same address.

--CTE. Defining 1 customer that have at least 43 rantals and payments records.
WITH customer_to_update AS (
	SELECT 
		c.customer_id,
		c.first_name,
		c.last_name,
		c.email,
		c.address_id
	FROM 
		public.customer c
	JOIN (
		SELECT 
			customer_id, 
			count(*) AS rental_cnt
		FROM 
			public.rental r
		GROUP BY
			customer_id
		HAVING
			count(*) >= 43
	) r ON
		c.customer_id = r.customer_id
	JOIN (
		SELECT 
			customer_id, 
			count(*) AS payment_cnt
		FROM 
			public.payment
		GROUP BY
			customer_id
		HAVING
			count(*) >= 43
	) p ON
		c.customer_id = p.customer_id
	LIMIT 1
) --Updating chosen customer personal to my personal data
UPDATE
	public.customer
SET 
	first_name = 'Dias',
	last_name = 'Yermekov',
	email = 'DIAS.YERMEKOV@sakilacustomer.org',
	address_id = (SELECT
						a.address_id
				  FROM
						public.address a
				  WHERE
						lower(a.address) = '669 firozabad loop' AND 
				  		lower(a.district) = 'abu dhabi'),
	last_update = current_date
WHERE
	customer_id = (SELECT customer_id FROM customer_to_update)
RETURNING customer_id, first_name, last_name, email, last_update;


--Remove any records related to you (as a customer) from all tables except 'Customer' and 'Inventory'
--I used delete instead of truncate to use with the condition because only a few lines had to be deleted.
DELETE FROM public.payment p WHERE p.customer_id = (SELECT 
														c.customer_id 
													FROM 
														public.customer c 
													WHERE lower(c.first_name) = 'dias' AND 
														  lower(c.last_name) = 'yermekov')
RETURNING p.payment_id, p.customer_id;

DELETE FROM public.rental r WHERE r.customer_id = (SELECT 
														c.customer_id 
													FROM 
														public.customer c 
													WHERE lower(c.first_name) = 'dias' AND 
														  lower(c.last_name) = 'yermekov')
RETURNING r.rental_id, r.customer_id;


--Rent you favorite movies from the store they are in and pay for them (add corresponding records to the database to represent this activity)
--(Note: to insert the payment_date into the table payment, you can create a new partition (see the scripts to install the training database )
--or add records for the first half of 2017)

CREATE TABLE public.payment_p2024_11 ( 
     payment_id integer DEFAULT nextval('public.payment_payment_id_seq'::regclass) NOT NULL, 
     customer_id smallint NOT NULL, 
     staff_id smallint NOT NULL, 
     rental_id integer NOT NULL, 
     amount numeric(5,2) NOT NULL, 
     payment_date timestamp with time zone NOT NULL); 

 ALTER TABLE public.payment_p2024_11 OWNER TO postgres;

ALTER TABLE ONLY public.payment ATTACH PARTITION public.payment_p2024_11 FOR VALUES FROM ('2024-10-31 23:00:00+02') TO ('2024-12-01 00:00:00+03');

-- Select film IDs that match the specified titles.
WITH favorite_films AS (
    SELECT 
        f.film_id
    FROM 
        public.film f 
    WHERE 
        lower(f.title) IN ('original title: the golden compass', 'green book', 'the chronicles of narnia: the lion, the witch and the wardrobe')
),-- Defining inventory information for the selected films.
selecting_inventory_store AS (
    SELECT 
        i.inventory_id,
        i.store_id,
        i.film_id
    FROM 
        public.inventory i
    JOIN favorite_films ff ON ff.film_id = i.film_id
),-- Geting the customer and staff IDs based on their names.
customer_and_staff AS (
    SELECT 
        (SELECT customer_id FROM public.customer WHERE lower(first_name) = 'dias' AND lower(last_name) = 'yermekov') AS customer_id, 
        (SELECT staff_id FROM public.staff WHERE lower(first_name) = 'hanna' AND lower(last_name) = 'rainbow' AND store_id = 1) AS staff_id
), -- Inserting rental data into the rental table and return rental, customer, and staff IDs.
rented_films AS (
    INSERT INTO public.rental (rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
    SELECT 
        now() AS rental_date, 
        si.inventory_id, 
        (SELECT customer_id FROM public.customer WHERE lower(first_name) = 'dias' AND lower(last_name) = 'yermekov') AS customer_id, 
        now() + 
        CASE 
            WHEN f.rental_duration = 1 THEN INTERVAL '7 days'
            WHEN f.rental_duration = 2 THEN INTERVAL '14 days'
            WHEN f.rental_duration = 3 THEN INTERVAL '21 days'
            ELSE INTERVAL '7 days'
        END AS return_date,
        (SELECT staff_id FROM public.staff WHERE lower(first_name) = 'hanna' AND lower(last_name) = 'rainbow' AND store_id = 1) AS staff_id,
        current_date AS last_update
    FROM selecting_inventory_store si
    JOIN public.film f ON f.film_id = si.film_id 
    RETURNING rental_id, rental_date, inventory_id, customer_id, return_date, staff_id, last_update
),-- Inserting payment data into the payment table using rental information and return payment details.
inserted_payments AS (
    INSERT INTO public.payment (customer_id, staff_id, rental_id, amount, payment_date)
    SELECT 
        r.customer_id, 
        r.staff_id, 
        r.rental_id, 
        f.rental_rate, 
        now() AS payment_date
    FROM rented_films r
    JOIN public.inventory i ON i.inventory_id = r.inventory_id 
    JOIN public.film f ON f.film_id = i.film_id
    RETURNING payment_id, customer_id, staff_id, rental_id, amount, payment_date
)
-- Select insertion records return as a combined result set.
SELECT 
    'Rental' AS record_type, 
    rental_id, 
    rental_date, 
    inventory_id, 
    customer_id, 
    return_date, 
    staff_id, 
    NULL AS payment_id, 
    NULL AS amount, 
    NULL AS payment_date,
    last_update
FROM rented_films
UNION ALL
SELECT 
    'Payment' AS record_type, 
    rental_id,  
    NULL AS rental_date,
    NULL AS inventory_id,
    customer_id, 
    NULL AS return_date,
    staff_id, 
    payment_id, 
    amount, 
    payment_date,
    NULL AS last_update
FROM inserted_payments;
