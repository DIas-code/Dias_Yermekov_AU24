/*
 Create a physical database with a separate database and schema and give it an appropriate domain-related name. Use the relational model you've created while studying DB Basics module. Task 2 (designing a logical data model on the chosen topic). Make sure you have made any changes to your model after your mentor's comments.
Your database must be in 3NF
Use appropriate data types for each column and apply DEFAULT values, and GENERATED ALWAYS AS columns as required.
Create relationships between tables using primary and foreign keys.
Apply five check constraints across the tables to restrict certain values, including
date to be inserted, which must be greater than January 1, 2000
inserted measured value that cannot be negative
inserted value that can only be a specific value (as an example of gender)
unique
not null

Populate the tables with the sample data generated, ensuring each table has at least two rows (for a total of 20+ rows in all the tables).
Add a not null 'record_ts' field to each table using ALTER TABLE statements, set the default value to current_date, and check to make sure the value has been set for the existing rows.



Note:
Your physical model should be in 3nf, all constraints, data types correspond your logical model
Your code must be reusable and rerunnable and executes without errors
Your code should not produces duplicates
Avoid hardcoding
Use appropriate data types
Add comments (as example why you chose particular constraint, datatytpe, etc.)
Please attached a graphical image with your fixed logical model


 */

CREATE DATABASE au24_dias_trainee;

CREATE SCHEMA IF NOT EXISTS subway_schema;


CREATE TABLE IF NOT EXISTS subway_schema."object"(
--	object_id SERIAL PRIMARY KEY,
--  Object id is not very usable for this table cause anyway 
--	for all references will be used object_code which more understanble
	object_code TEXT PRIMARY KEY,
    object_type VARCHAR(20) NOT NULL,
    status VARCHAR(16) NOT NULL,
    last_update DATE NOT NULL CHECK (last_update > '2000-01-01') 
);

 -- full_line IS NOT PK cause it can be changed, FOR example there was expand OF subway_line so FULL line will CHANGE.
-- thats why it is not primary key.
CREATE TABLE IF NOT EXISTS subway_schema.subway_line(
    subway_line_id SERIAL PRIMARY KEY,
    full_line TEXT UNIQUE NOT NULL,
    distance INT CHECK (distance >= 0) NOT NULL,
    station_quantity INT CHECK (station_quantity >= 0) NOT NULL
);


CREATE TABLE IF NOT EXISTS subway_schema.station(
    station_id SERIAL PRIMARY KEY,
    station_name VARCHAR(30) UNIQUE NOT NULL,
    address VARCHAR(30) UNIQUE NOT NULL,
    open_time TIME DEFAULT '08:00' NOT NULL,
    close_time TIME DEFAULT '22:00' NOT NULL,
    object_code TEXT UNIQUE NOT NULL REFERENCES subway_schema."object"(object_code),
    subway_line_id INT NOT NULL REFERENCES subway_schema.subway_line(subway_line_id)
);

CREATE TABLE IF NOT EXISTS subway_schema.tunnel(
	tunnel_id SERIAL PRIMARY KEY,
    subway_line_id INT NOT NULL REFERENCES subway_schema.subway_line(subway_line_id),
    start_station_id INT NOT NULL REFERENCES subway_schema.station(station_id),
    end_station_id INT NOT NULL REFERENCES subway_schema.station(station_id),
    object_code TEXT UNIQUE NOT NULL REFERENCES subway_schema."object"(object_code)
);

CREATE TABLE IF NOT EXISTS subway_schema.train(
    train_id SERIAL PRIMARY KEY,
    subway_line_id INT NOT NULL REFERENCES subway_schema.subway_line(subway_line_id),
    capacity INT CHECK (capacity >= 0) NOT NULL,
    object_code TEXT UNIQUE NOT NULL REFERENCES subway_schema."object"(object_code)
);

CREATE TABLE IF NOT EXISTS subway_schema.maintenance(
	maintenance_id SERIAL PRIMARY KEY,
    object_code TEXT NOT NULL REFERENCES subway_schema."object"(object_code),
    maintenance_type VARCHAR(30) NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    description TEXT
);

CREATE TABLE IF NOT EXISTS subway_schema.schedule(
	schedule_id SERIAL PRIMARY KEY,
    station_id INT NOT NULL REFERENCES subway_schema.station(station_id),
    subway_line_id INT NOT NULL REFERENCES subway_schema.subway_line(subway_line_id),
    train_id INT NOT NULL REFERENCES subway_schema.train(train_id),
    arrival_time TIME NOT NULL,
    departure_time TIME NOT NULL
);

CREATE TABLE IF NOT EXISTS subway_schema.employee(
    employee_id SERIAL PRIMARY KEY,
    work_field VARCHAR(15) NOT NULL,
    "position" VARCHAR(20) NOT NULL,
    first_name VARCHAR(20) NOT NULL,
    last_name VARCHAR(25) NOT NULL,
    personal_id VARCHAR(12) UNIQUE NOT NULL,
    phone_number VARCHAR(12) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS subway_schema.employee_station(
	employee_station_id SERIAL PRIMARY KEY,
    station_id INT NOT NULL REFERENCES subway_schema.station(station_id),
    employee_id INT NOT NULL REFERENCES subway_schema.employee(employee_id),
    work_date DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS subway_schema.employee_train(
	train_employee_id SERIAL PRIMARY KEY,
    train_id INT NOT NULL REFERENCES subway_schema.train(train_id),
    employee_id INT NOT NULL REFERENCES subway_schema.employee(employee_id),
    work_date DATE NOT NULL CHECK (work_date > '2000-01-01')
);

CREATE TABLE IF NOT EXISTS subway_schema.employee_maintenance(
	employee_maintenance_id SERIAL PRIMARY KEY,
    maintenance_id INT NOT NULL REFERENCES subway_schema.maintenance(maintenance_id),
    employee_id INT NOT NULL REFERENCES subway_schema.employee(employee_id)
);

CREATE TABLE IF NOT EXISTS subway_schema.ticket(
	ticket_id SERIAL PRIMARY KEY, 
    station_id INT NOT NULL UNIQUE REFERENCES subway_schema.station(station_id) -- added CONSTRAINT UNIQUE
    --All tickets for specific station are same, only their ids are different.
    --Station id wasnt unique for some reports, but we can take it from payment table
    --where I deleted constraint unique from ticket_id. So, this table will be for ticket type, 
    --because all physical tickets are fully same.
);

CREATE TABLE IF NOT EXISTS subway_schema.discount(
	discount_id SERIAL PRIMARY KEY,
    discount_type VARCHAR(50) UNIQUE,
    discount_percent INT DEFAULT 0 CHECK (discount_percent BETWEEN 0 AND 100)
);

CREATE TABLE IF NOT EXISTS subway_schema.payment(
	payment_id SERIAL PRIMARY KEY,
    payment_type VARCHAR(20) NOT NULL,
    discount_id INT DEFAULT 1 REFERENCES subway_schema.discount(discount_id),
    cost_amount DECIMAL DEFAULT 100.00 NOT NULL CHECK (cost_amount >= 0),
    ticket_id INT NOT NULL REFERENCES subway_schema.ticket(ticket_id), -- Deleted CONSTRAINT unique
    payment_date TIMESTAMP NOT NULL
);

--DROP TABLE subway_schema.ticket ; 
--DROP TABLE subway_schema.payment ;

--Creating composite pk on tunnel, fistr deleting contsraint pk that we had, and adding new constraint composite pk.
ALTER TABLE subway_schema.tunnel
DROP CONSTRAINT tunnel_pkey,
ADD CONSTRAINT pk_tunnel PRIMARY KEY (start_station_id, end_station_id);

-- Check if there is only a card or cash in the payment_type
ALTER TABLE subway_schema.payment
ADD CONSTRAINT payment_type_check 
CHECK (payment_type IN ('card', 'cash'));

--Added missing constraints 
ALTER TABLE subway_schema.payment
ALTER COLUMN payment_date SET DEFAULT now();

ALTER TABLE subway_schema.payment
ADD CONSTRAINT chech_payment_date
CHECK (payment_date > '2000-01-01');

ALTER TABLE subway_schema.employee_station
ADD CONSTRAINT check_work_date
CHECK (work_date > '2000-01-01');

ALTER TABLE subway_schema.maintenance
ADD CONSTRAINT check_start_time 
CHECK (start_time > '2001-01-01'),
ADD CONSTRAINT check_end_time 
CHECK (end_time >= start_time);

-- Altering tables to increase varchar size
ALTER TABLE subway_schema."object" ALTER status TYPE VARCHAR(30);

ALTER TABLE subway_schema.employee
    ALTER COLUMN "position" TYPE VARCHAR(30),
    ALTER COLUMN first_name TYPE VARCHAR(30),
    ALTER COLUMN last_name TYPE VARCHAR(30);

-- Added generated always as in employee table
ALTER TABLE subway_schema.employee 
ADD COLUMN full_name TEXT GENERATED ALWAYS AS (first_name || ' '|| last_name) STORED;

ALTER TABLE subway_schema.employee 
ADD CONSTRAINT full_name_not_null CHECK (full_name IS NOT null);


--Adding data
-- Insert into subway_schema."object"
WITH new_objects AS (
    SELECT 'ST001' AS object_code,'Station' AS object_type, 'Under Maintenance' AS status, '2024-11-10 04:00'::TIMESTAMP AS last_update
    UNION ALL 
    SELECT 'TR001', 'Train', 'Under Maintenance', '2024-11-10 04:00'::TIMESTAMP
    UNION ALL 
    SELECT 'TR002', 'Train', 'Under Maintenance', '2024-10-29 13:00'::TIMESTAMP
    UNION ALL 
    SELECT 'TR003', 'Train', 'Out of Service', '2024-10-29 04:00'::TIMESTAMP
    UNION ALL 
    SELECT 'TU001', 'Tunnel', 'Active', '2024-11-01 08:00'::TIMESTAMP
    UNION ALL 
    SELECT 'ST002', 'Station', 'Active', '2024-10-29 04:00'::TIMESTAMP
    UNION ALL 
    SELECT 'TU003', 'Tunnel', 'Active', '2024-11-10 04:10'::TIMESTAMP
    UNION ALL 
    SELECT 'ST003', 'Station', 'Active', '2024-10-29 04:00'::TIMESTAMP
), -- CTE for inserting new objects with checking on existing in database
inserted_objects AS (
    INSERT INTO subway_schema."object" (object_code, object_type, status, last_update)
    SELECT 
    	nobj.object_code,
        nobj.object_type,
        nobj.status,
        nobj.last_update
    FROM 
        new_objects nobj
    WHERE NOT EXISTS(SELECT 1 FROM subway_schema."object" o 
    				 WHERE o.object_code = nobj.object_code)
    RETURNING object_code, object_type, status, last_update
)
SELECT object_code, object_type, status, last_update FROM inserted_objects;

UPDATE subway_schema."object" 
SET object_code = 'TU002'
WHERE object_code = 'TU003';

SELECT * FROM subway_schema."object" o ;
--TRUNCATE subway_schema."object" cascade;
--ALTER SEQUENCE subway_schema."object_object_id_seq" RESTART WITH 1;

-- Insert for subway_schema.subway_line
WITH new_subway_lines AS ( 
    SELECT 'Zhibek Zholy-Abay-Seyfulina-Almaly-Momyshuly-Alatau-Moscow' AS full_line, -- Cannot be NULL cause it have NOT NULL constraint
    		21 AS distance, 
    		7 AS station_quantity
)
INSERT INTO subway_schema.subway_line (full_line, distance, station_quantity)
SELECT nsl.full_line, nsl.distance, nsl.station_quantity
FROM new_subway_lines nsl
WHERE NOT EXISTS (
    SELECT 1 FROM subway_schema.subway_line sl
    WHERE sl.full_line = nsl.full_line
);

SELECT * FROM subway_schema.subway_line sl ;

-- Insert for subway_schema.station
WITH new_stations AS (
    SELECT 'ST001' AS object_code, 'Zhibek Zholy' AS station_name, 'Zhibek Zholy 1' AS address,
    (SELECT sl.subway_line_id FROM subway_schema.subway_line sl 
   		 WHERE sl.full_line = 'Zhibek Zholy-Abay-Seyfulina-Almaly-Momyshuly-Alatau-Moscow') AS subway_line_id
    UNION ALL 
    SELECT 'ST002', 'Abay', 'Abay 57',
		(SELECT sl.subway_line_id FROM subway_schema.subway_line sl 
   		 WHERE sl.full_line = 'Zhibek Zholy-Abay-Seyfulina-Almaly-Momyshuly-Alatau-Moscow')
    UNION ALL 
    SELECT 'ST003', 'Seyfulina', 'Seyfulina 22',
    	(SELECT sl.subway_line_id FROM subway_schema.subway_line sl 
   		 WHERE sl.full_line = 'Zhibek Zholy-Abay-Seyfulina-Almaly-Momyshuly-Alatau-Moscow')
)
INSERT INTO subway_schema.station (station_name, address, object_code, subway_line_id)
SELECT ns.station_name, ns.address, ns.object_code, ns.subway_line_id
FROM new_stations ns
WHERE NOT EXISTS (
    SELECT 1 FROM subway_schema.station s
    WHERE s.object_code = ns.object_code
);

SELECT * FROM subway_schema.station ;

-- Insert for subway_schema.train
WITH new_trains AS (
    SELECT 'TR001' AS object_code, 
    	(SELECT sl.subway_line_id FROM subway_schema.subway_line sl 
   		 WHERE sl.full_line = 'Zhibek Zholy-Abay-Seyfulina-Almaly-Momyshuly-Alatau-Moscow') AS subway_line_id,
   		 800 AS capacity
    UNION ALL 
    SELECT 'TR002', (SELECT sl.subway_line_id FROM subway_schema.subway_line sl 
   		 WHERE sl.full_line = 'Zhibek Zholy-Abay-Seyfulina-Almaly-Momyshuly-Alatau-Moscow'),
   		 1000
    UNION ALL 
    SELECT 'TR003', 
    	(SELECT sl.subway_line_id FROM subway_schema.subway_line sl 
   		 WHERE sl.full_line = 'Zhibek Zholy-Abay-Seyfulina-Almaly-Momyshuly-Alatau-Moscow'),
   		 0
)
INSERT INTO subway_schema.train (object_code, subway_line_id, capacity)
SELECT nt.object_code, nt.subway_line_id, nt.capacity
FROM new_trains nt
WHERE NOT EXISTS (
    SELECT 1 FROM subway_schema.train t
    WHERE t.object_code = nt.object_code
);

SELECT * FROM subway_schema.train;

-- Insert for subway_schema.tunnel
WITH new_tunnels AS (
    SELECT 	
    	(SELECT sl.subway_line_id FROM subway_schema.subway_line sl 
   		 WHERE sl.full_line = 'Zhibek Zholy-Abay-Seyfulina-Almaly-Momyshuly-Alatau-Moscow') AS subway_line_id, 
    	(SELECT s.station_id FROM subway_schema.station s WHERE s.station_name = 'Zhibek Zholy') AS start_station_id, 
    	(SELECT s.station_id FROM subway_schema.station s WHERE s.station_name = 'Abay') AS end_station_id, 
    	  'TU001' AS object_code
    UNION ALL 
    SELECT 
    	(SELECT sl.subway_line_id FROM subway_schema.subway_line sl 
   		WHERE sl.full_line = 'Zhibek Zholy-Abay-Seyfulina-Almaly-Momyshuly-Alatau-Moscow'), 
   		(SELECT s.station_id FROM subway_schema.station s WHERE s.station_name = 'Abay'),
  	    (SELECT s.station_id FROM subway_schema.station s WHERE s.station_name = 'Seyfulina'),
   	    'TU002'
)
INSERT INTO subway_schema.tunnel (subway_line_id, start_station_id, end_station_id, object_code)
SELECT nt.subway_line_id, nt.start_station_id, nt.end_station_id, nt.object_code
FROM new_tunnels nt
WHERE NOT EXISTS (
    SELECT 1 FROM subway_schema.tunnel t
    WHERE (t.start_station_id = nt.start_station_id 
      AND t.end_station_id = nt.end_station_id)
      OR t.object_code = nt.object_code
);

SELECT * FROM subway_schema.tunnel ;

-- Insert for subway_schema.schedule
WITH new_schedules AS (
    SELECT 
    	(SELECT s.station_id FROM subway_schema.station s WHERE s.station_name = 'Zhibek Zholy') AS station_id, 
    	(SELECT sl.subway_line_id FROM subway_schema.subway_line sl 
   		WHERE sl.full_line = 'Zhibek Zholy-Abay-Seyfulina-Almaly-Momyshuly-Alatau-Moscow') AS subway_line_id, 
    	(SELECT train_id FROM subway_schema.train WHERE object_code = 'TR001') AS train_id, 
    	'08:00'::TIME AS arrival_time, 
    	'08:05'::TIME AS departure_time
    UNION ALL 
    SELECT 
    	(SELECT s.station_id FROM subway_schema.station s WHERE s.station_name = 'Abay') AS station_id, 
    	(SELECT sl.subway_line_id FROM subway_schema.subway_line sl 
   		WHERE sl.full_line = 'Zhibek Zholy-Abay-Seyfulina-Almaly-Momyshuly-Alatau-Moscow') AS subway_line_id, 
    	(SELECT train_id FROM subway_schema.train WHERE object_code = 'TR001') AS train_id, 
    	'08:12'::TIME AS arrival_time, 
    	'08:17'::TIME AS departure_time
)
INSERT INTO subway_schema.schedule (station_id, subway_line_id, train_id, arrival_time, departure_time)
SELECT ns.station_id, ns.subway_line_id, ns.train_id, ns.arrival_time, ns.departure_time
FROM new_schedules ns
WHERE NOT EXISTS (SELECT 1 FROM subway_schema.schedule s 
	WHERE s.station_id = ns.station_id
	AND s.train_id = ns.train_id
	AND ns.arrival_time=s.arrival_time 
	)
;

SELECT * FROM subway_schema.schedule;

-- Insert for subway_schema.maintenance
WITH new_maintenance AS (
    SELECT 1 AS maintenance_id, 'TR001' AS object_code, 'Repair' AS maintenance_type, '2024-10-29 13:00'::TIMESTAMP AS start_time, NULL AS end_time
    UNION ALL 
    SELECT 2, 'TU001', 'scheduled inspection', '2024-11-01 06:00'::TIMESTAMP, '2024-11-01 08:00'::TIMESTAMP
    UNION ALL 
    SELECT 3, 'TU002', 'scheduled inspection', '2024-11-01 06:00'::TIMESTAMP, '2024-11-01 08:00'::TIMESTAMP
    UNION ALL 
    SELECT 4, 'TR002', 'scheduled inspection', '2024-11-02 04:00'::TIMESTAMP, '2024-11-02 06:00'::TIMESTAMP
    UNION ALL 
    SELECT 5, 'ST001', 'scheduled inspection', '2024-11-10 04:00'::TIMESTAMP, NULL
    UNION ALL 
    SELECT 6, 'TR002', 'Repair', '2024-11-10 04:00'::TIMESTAMP, NULL
    UNION ALL 
    SELECT 7, 'TU002', 'scheduled inspection', '2024-11-10 04:10'::TIMESTAMP, NULL
)
INSERT INTO subway_schema.maintenance (maintenance_id, object_code, maintenance_type, start_time, end_time)
SELECT nm.maintenance_id, nm.object_code, nm.maintenance_type, nm.start_time, nm.end_time
FROM new_maintenance nm
WHERE NOT EXISTS (
    SELECT 1 FROM subway_schema.maintenance m
    WHERE m.maintenance_id = nm.maintenance_id
);

SELECT * FROM subway_schema.maintenance;

-- Insert for subway_schema.employee
WITH new_employees AS (
    SELECT 'Train' AS Work_Field, 'Train Operator' AS Position, 'Dias' AS First_Name, 'Yermekov' AS Last_name, '021114500029' AS Personal_ID, '+77011234567' AS Phone_Number
    UNION ALL 
    SELECT 'Train', 'Inspector', 'Aziz', 'Abikenov', '990113300029', '+77012345678'
    UNION ALL 
    SELECT 'Train', 'Inspector', 'Maira', 'Aslanova', '980707400029', '+77023456789'
    UNION ALL 
    SELECT 'Station', 'Ticketing Clerk', 'Lucas', 'Thomas', '830927300009', '+77034567890'
    UNION ALL 
    SELECT 'Station', 'Safety Inspector', 'Lee', 'Mason', '780315300008', '+77045678901'
    UNION ALL 
    SELECT 'Station', 'Platform Attendant', 'Elizabeth', 'Williams', '721123400010', '+77056789012'
    UNION ALL 
    SELECT 'Maintenance', 'Maintenance Technician', 'William', 'Randow', '650504300006', '+77067890123'
    UNION ALL 
    SELECT 'Maintenance', 'Electrical Engineer', 'William', 'Davis', '871223300005', '+77078901234'
    UNION ALL 
    SELECT 'Maintenance', 'Mechanical Engineer', 'John', 'Smith', '900812300007', '+77089012345'
)
INSERT INTO subway_schema.employee (Work_Field, Position, First_Name, Last_name, Personal_ID, Phone_Number)
SELECT ne.Work_Field, ne.Position, ne.First_Name, ne.Last_name, ne.Personal_ID, ne.Phone_Number
FROM new_employees ne
WHERE NOT EXISTS (
    SELECT 1 FROM subway_schema.employee e
    WHERE e.Personal_ID = ne.Personal_ID
);

SELECT * FROM subway_schema.employee;

-- Insert for subway_schema.employee_train
WITH new_train_employee AS (
    SELECT (SELECT train_id FROM subway_schema.train 
    		WHERE object_code = 'TR001') AS train_id,
    		(SELECT employee_id FROM subway_schema.employee
    		 WHERE personal_id = '021114500029') AS employee_id,
    		 '2024-11-08'::date AS work_date
    UNION ALL 
    SELECT (SELECT train_id FROM subway_schema.train 
    		WHERE object_code = 'TR002'),
    		(SELECT employee_id FROM subway_schema.employee
    		 WHERE personal_id = '980707400029'),
    		 '2024-11-08'::date
    UNION ALL 
    SELECT (SELECT train_id FROM subway_schema.train 
    		WHERE object_code = 'TR001'),
    		(SELECT employee_id FROM subway_schema.employee
    		 WHERE personal_id = '990113300029'),
    		 '2024-11-08'::date
   	UNION ALL 
    SELECT (SELECT train_id FROM subway_schema.train 
    		WHERE object_code = 'TR002'),
    		(SELECT employee_id FROM subway_schema.employee
    		 WHERE personal_id = '021114500029'),
    		 '2024-11-09'::date
)
INSERT INTO subway_schema.employee_train (train_id, employee_id, work_date)
SELECT nte.train_id, nte.employee_id, nte.work_date
FROM new_train_employee nte
WHERE NOT EXISTS (
    SELECT 1 FROM subway_schema.employee_train te
    WHERE te.train_id = nte.train_id
    AND te.employee_id = nte.employee_id
    AND te.work_date = nte.work_date
);

SELECT * FROM subway_schema.employee_train;

-- Insert for subway_schema.employee_station
WITH new_station_employee AS (
    SELECT (SELECT station_id FROM subway_schema.station 
    		WHERE object_code = 'ST001') AS station_id,
    		(SELECT employee_id FROM subway_schema.employee
    		 WHERE personal_id = '021114500029') AS employee_id,
    		 '2024-11-08'::date AS work_date
    UNION ALL 
    SELECT (SELECT station_id FROM subway_schema.station 
    		WHERE object_code = 'ST001'),
    		(SELECT employee_id FROM subway_schema.employee
    		 WHERE personal_id = '980707400029'),
    		 '2024-11-08'::date
    UNION ALL 
    SELECT (SELECT station_id FROM subway_schema.station 
    		WHERE object_code = 'ST002'),
    		(SELECT employee_id FROM subway_schema.employee
    		 WHERE personal_id = '990113300029'),
    		 '2024-11-08'::date
   	UNION ALL 
    SELECT (SELECT station_id FROM subway_schema.station 
    		WHERE object_code = 'ST002'),
    		(SELECT employee_id FROM subway_schema.employee
    		 WHERE personal_id = '021114500029'),
    		 '2024-11-09'::date
)
INSERT INTO subway_schema.employee_station (station_id, employee_id, work_date)
SELECT nse.station_id, nse.employee_id, nse.work_date
FROM new_station_employee nse
WHERE NOT EXISTS (
    SELECT 1 FROM subway_schema.employee_station se
    WHERE se.station_id = nse.station_id
    AND se.employee_id = nse.employee_id
    AND se.work_date = nse.work_date
);

SELECT * FROM subway_schema.employee_station;

-- Insert for subway_schema.employee_maintenance
WITH new_maintenance_employee AS (
    SELECT (SELECT maintenance_id FROM subway_schema.maintenance 
    		WHERE object_code = 'TR001' AND start_time = '2024-10-29 13:00:00.000'::TIMESTAMP) AS maintenance_id,
    		(SELECT employee_id FROM subway_schema.employee
    		 WHERE personal_id = '871223300005') AS employee_id
    UNION ALL 
    SELECT (SELECT maintenance_id FROM subway_schema.maintenance 
    		WHERE object_code = 'TU001' AND start_time = '2024-11-01 06:00:00.000'::TIMESTAMP),
    		(SELECT employee_id FROM subway_schema.employee
    		 WHERE personal_id = '650504300006')
    UNION ALL 
    SELECT (SELECT maintenance_id FROM subway_schema.maintenance 
    		WHERE object_code = 'TU002' AND start_time = '2024-11-01 06:00:00.000'::TIMESTAMP),
    		(SELECT employee_id FROM subway_schema.employee
    		 WHERE personal_id = '650504300006')
   	UNION ALL 
    SELECT (SELECT maintenance_id FROM subway_schema.maintenance 
    		WHERE object_code = 'TR002' AND start_time = '2024-11-02 04:00:00.000'::TIMESTAMP),
    		(SELECT employee_id FROM subway_schema.employee
    		 WHERE personal_id = '650504300006')
    UNION ALL 
    SELECT (SELECT maintenance_id FROM subway_schema.maintenance 
    		WHERE object_code = 'ST001' AND start_time = '2024-11-10 04:00:00.000'::TIMESTAMP),
    		(SELECT employee_id FROM subway_schema.employee
    		 WHERE personal_id = '650504300006')
    UNION ALL 
    SELECT (SELECT maintenance_id FROM subway_schema.maintenance 
    		WHERE object_code = 'TR002' AND start_time = '2024-11-10 04:00:00.000'::TIMESTAMP),
    		(SELECT employee_id FROM subway_schema.employee
    		 WHERE personal_id = '900812300007')
   	UNION ALL 
    SELECT (SELECT maintenance_id FROM subway_schema.maintenance 
    		WHERE object_code = 'TU002' AND start_time = '2024-11-10 04:10:00.000'::TIMESTAMP),
    		(SELECT employee_id FROM subway_schema.employee
    		 WHERE personal_id = '650504300006')
)
INSERT INTO subway_schema.employee_maintenance (maintenance_id, employee_id)
SELECT nme.maintenance_id, nme.employee_id
FROM new_maintenance_employee nme
WHERE NOT EXISTS (
    SELECT 1 FROM subway_schema.employee_maintenance me
    WHERE me.maintenance_id = nme.maintenance_id
    AND me.employee_id = nme.employee_id
);

SELECT * FROM subway_schema.employee_maintenance;
SELECT * FROM subway_schema.station s ;

-- Insert into subway_schema.ticket
WITH new_tickets AS (
    SELECT (SELECT station_id FROM subway_schema.station s
    		WHERE s.station_name = 'Abay') AS station_id  
    UNION ALL 
    SELECT (SELECT station_id FROM subway_schema.station s
    		WHERE s.station_name = 'Zhibek Zholy')
--    UNION ALL 
--    SELECT (SELECT station_id FROM subway_schema.station s
--    		WHERE s.station_name = 'Zhibek Zholy')
--    UNION ALL 
--    SELECT (SELECT station_id FROM subway_schema.station s
--    		WHERE s.station_name = 'Abay')
)
INSERT INTO subway_schema.ticket (station_id)
SELECT 
    	nt.station_id
FROM 
     new_tickets nt
WHERE NOT EXISTS (SELECT 1 FROM subway_schema.ticket t
				  WHERE nt.station_id = t.station_id); 

SELECT * FROM subway_schema.ticket t;

-- Insert into subway_schema.discount
WITH new_discounts AS (
    SELECT 'standart' AS discount_type, 0 AS discount_percent
    UNION ALL 
    SELECT 'school_student', 100
    UNION ALL 
    SELECT 'university_student', 50
    UNION ALL 
    SELECT 'disability', 100
)
INSERT INTO subway_schema.discount (discount_type, discount_percent)
SELECT 
    	nd.discount_type,
    	nd.discount_percent
FROM 
     new_discounts nd
WHERE NOT EXISTS (SELECT 1 FROM subway_schema.discount d
				  WHERE d.discount_type = nd.discount_type); 

SELECT * FROM subway_schema.discount;

-- Insert into subway_schema.payment
WITH new_payments AS (
    SELECT 'card' AS payment_type, 
    		(SELECT discount_id FROM subway_schema.discount
    		 WHERE lower(discount_type) = 'school_student') AS discount_id,
    		 (SELECT ticket_id FROM subway_schema.ticket
    		  JOIN subway_schema.station s using(station_id)
			  WHERE s.station_name = 'Abay') AS ticket_id,
			 0 AS cost_amount
    UNION ALL 
    SELECT 'cash' AS payment_type, 
    		(SELECT discount_id FROM subway_schema.discount
    		 WHERE lower(discount_type) = 'school_student') AS discount_id,
    		 (SELECT ticket_id FROM subway_schema.ticket
    		  JOIN subway_schema.station s using(station_id)
			  WHERE s.station_name = 'Abay') AS ticket_id,
    		 100
    UNION ALL 
    SELECT 'cash' AS payment_type, 
    		(SELECT discount_id FROM subway_schema.discount
    		 WHERE lower(discount_type) = 'school_student') AS discount_id,
    		 (SELECT ticket_id FROM subway_schema.ticket
    		  JOIN subway_schema.station s using(station_id)
			  WHERE s.station_name = 'Zhibek Zholy') AS ticket_id,
    		 50
    UNION ALL 
    SELECT 'card' AS payment_type, 
    		(SELECT discount_id FROM subway_schema.discount
    		 WHERE lower(discount_type) = 'school_student') AS discount_id,
    		 (SELECT ticket_id FROM subway_schema.ticket
    		  JOIN subway_schema.station s using(station_id)
			  WHERE s.station_name = 'Abay') AS ticket_id,
    		 0
)
INSERT INTO subway_schema.payment (payment_type, discount_id, ticket_id, cost_amount)
SELECT 
    	np.payment_type,
    	np.discount_id,
    	np.ticket_id,
    	np.cost_amount
FROM 
     new_payments np 
WHERE NOT EXISTS (SELECT 1 FROM subway_schema.payment p
				  WHERE p.ticket_id = np.ticket_id);
				 
SELECT * FROM subway_schema.payment;

--TRUNCATE subway_schema.payment;

ALTER TABLE subway_schema.object 
ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

ALTER TABLE subway_schema.subway_line 
ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

ALTER TABLE subway_schema.tunnel 
ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

ALTER TABLE subway_schema.station 
ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

ALTER TABLE subway_schema.train 
ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

ALTER TABLE subway_schema.maintenance 
ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

ALTER TABLE subway_schema.schedule 
ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

ALTER TABLE subway_schema.employee 
ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

ALTER TABLE subway_schema.employee_station 
ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

ALTER TABLE subway_schema.employee_train 
ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

ALTER TABLE subway_schema.employee_maintenance 
ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

ALTER TABLE subway_schema.ticket 
ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

ALTER TABLE subway_schema.discount 
ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

ALTER TABLE subway_schema.payment 
ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT CURRENT_DATE NOT NULL;
