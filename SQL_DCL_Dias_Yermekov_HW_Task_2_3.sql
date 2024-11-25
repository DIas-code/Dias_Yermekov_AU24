-- Task 2. Implement role-based authentication model for dvd_rental database

-- 1. Create a new user with the username "rentaluser" and the password "rentalpassword". 
-- Give the user the ability to connect to the database but no other permissions.
CREATE USER rentaluser WITH PASSWORD 'rentalpassword';

GRANT CONNECT ON DATABASE dvdrental TO rentaluser;
--REVOKE ALL PRIVILEGES ON TABLE public.customer FROM rentaluser;
--REVOKE ALL PRIVILEGES ON TABLE public.rental FROM rental;
--DROP USER rentaluser;
--DROP GROUP rental;

--
--SELECT * FROM public.actor a ;

-- 2. Grant "rentaluser" SELECT permission for the "customer" table. 
-- Сheck to make sure this permission works correctly—write a SQL query to select all customers.

GRANT SELECT ON TABLE public.customer TO rentaluser;

-- Checking availability of select on customer, and no one else
SELECT * FROM public.customer ;
SELECT * FROM public.payment p ;

-- Authorization yo rentaluser and checking for current user.
SET SESSION AUTHORIZATION rentaluser;
SELECT CURRENT_USER;

-- 3. Create a new user group called "rental" and add "rentaluser" to the group.
 
--CREATE GROUP rental WITH USER rentaluser ; I found out that groups are only used for compatibility with older versions

CREATE ROLE rental WITH USER rentaluser ;

-- 4. Grant the "rental" group INSERT and UPDATE permissions for the "rental" table. 
-- Insert a new row and update one existing row in the "rental" table under that role. 

--GRANT INSERT, UPDATE, SELECT ON TABLE public.rental TO rental; used for faster checking
--SELECT * FROM public.rental ORDER BY rental_id DESC;

GRANT INSERT, UPDATE ON TABLE public.rental TO rental;

INSERT INTO public.rental(rental_id, rental_date, inventory_id, customer_id, return_date, staff_id) 
VALUES (32307, now(), 4595, 1, now()+INTERVAL '7 days', 4);

UPDATE public.rental 
SET return_date = (SELECT rental_date FROM public.rental WHERE rental_id = 32307) + INTERVAL '14 days'
WHERE rental_id = 32307;

-- 5. Revoke the "rental" group's INSERT permission for the "rental" table. 
-- Try to insert new rows into the "rental" table make sure this action is denied.

REVOKE INSERT ON TABLE public.rental FROM rental;

-- Checking of not workng INSERT and working UPDATE.
INSERT INTO public.rental(rental_id, rental_date, inventory_id, customer_id, return_date, staff_id) 
VALUES (32308, now(), 4594, 1, now()+INTERVAL '7 days', 4);

UPDATE public.rental 
SET return_date = (SELECT rental_date FROM public.rental WHERE rental_id = 32307) + INTERVAL '14 days'
WHERE rental_id = 32307;


-- 6. Create a personalized role for any customer already existing in the dvd_rental database. 
-- The name of the role name must be client_{first_name}_{last_name} (omit curly brackets). 
-- The customer's payment and rental history must not be empty. 

SELECT * FROM public.customer c 
JOIN public.rental r ON r.customer_id = c.customer_id 
JOIN public.payment p ON p.customer_id = c.customer_id
LIMIT 1;

CREATE ROLE client_tommy_collazo WITH;
GRANT CONNECT ON DATABASE dvdrental TO rentaluser;
GRANT SELECT ON TABLE public.film, public.actor TO client_tommy_collazo;

SET ROLE client_tommy_collazo;


-- Task 3. Implement row-level security
-- Read about row-level security (https://www.postgresql.org/docs/12/ddl-rowsecurity.html) 
-- Configure that role so that the customer can only access their own data in the "rental" and "payment" tables. 
-- Write a query to make sure this user sees only their own data.


ALTER TABLE public.payment ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rental ENABLE ROW LEVEL SECURITY;

--SELECT * 
--FROM public.customer c 
--JOIN public.rental r ON r.customer_id = c.customer_id 
--JOIN public.payment p ON p.customer_id = c.customer_id
--ORDER BY RANDOM()
--LIMIT 1;

-- Used id IN name OF USER FOR uniqueness, because FULL names can have duplicates 
-- and not used email cause it can be NUll.

CREATE ROLE ELLEN_SIMPSON_126; 
SET ROLE ELLEN_SIMPSON_126;
--GRANT SELECT ON public.customer, public.rental, public.payment TO ELLEN_SIMPSON_126; used for checking
GRANT SELECT ON public.rental, public.payment TO ELLEN_SIMPSON_126;


CREATE OR REPLACE FUNCTION get_user_id()
RETURNS int AS $$
BEGIN
	RETURN (
	SELECT customer_id FROM customer
	WHERE CAST(split_part(current_user, '_', 3) AS int)  = customer_id
	);
END;
$$ LANGUAGE plpgsql;


CREATE POLICY only_current_customer_payment ON public.payment USING (customer_id = get_user_id());

SELECT * FROM public.payment;

CREATE POLICY only_current_customer_rental ON public.rental USING (customer_id = get_user_id());

SELECT * FROM public.rental;



