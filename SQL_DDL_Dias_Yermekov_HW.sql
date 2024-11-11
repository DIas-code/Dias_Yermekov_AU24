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
	object_id SERIAL PRIMARY KEY,
    object_type VARCHAR(20) NOT NULL,
    status VARCHAR(16) NOT NULL,
    last_update DATE NOT NULL CHECK (last_update > '2000-01-01') 
);

CREATE TABLE IF NOT EXISTS subway_schema.subway_line(
    subway_line_id SERIAL PRIMARY KEY,
    full_line TEXT UNIQUE NOT NULL,
    distance INT CHECK (distance >= 0) NOT NULL,
    station_quantity INT CHECK (station_quantity >= 0) NOT NULL
);

CREATE TABLE IF NOT EXISTS subway_schema.tunnel(
	tunnel_id SERIAL PRIMARY KEY,
    subway_line_id INT NOT NULL REFERENCES subway_schema.subway_line(subway_line_id),
    start_station_id INT NOT NULL,
    end_station_id INT NOT NULL,
    object_id INT UNIQUE NOT NULL REFERENCES subway_schema.OBJECT(object_id)
);

CREATE TABLE IF NOT EXISTS subway_schema.station(
    station_id SERIAL PRIMARY KEY,
    station_name VARCHAR(30) UNIQUE NOT NULL,
    address VARCHAR(30) UNIQUE NOT NULL,
    open_time TIME DEFAULT '08:00' NOT NULL,
    close_time TIME DEFAULT '22:00' NOT NULL,
    object_id INT UNIQUE NOT NULL REFERENCES subway_schema.OBJECT(object_id),
    subway_line_id INT NOT NULL REFERENCES subway_schema.subway_line(subway_line_id)
);

CREATE TABLE IF NOT EXISTS subway_schema.train(
    train_id SERIAL PRIMARY KEY,
    serial_number VARCHAR(20) UNIQUE NOT NULL,
    subway_line_id INT NOT NULL REFERENCES subway_schema.subway_line(subway_line_id),
    capacity INT CHECK (capacity >= 0) NOT NULL,
    object_id INT UNIQUE NOT NULL REFERENCES subway_schema.object(object_id)
);

CREATE TABLE IF NOT EXISTS subway_schema.maintenance(
	maintenance_id SERIAL PRIMARY KEY,
    object_id INT NOT NULL REFERENCES subway_schema.object(object_id),
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
    date DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS subway_schema.employee_train(
	train_employee_id SERIAL PRIMARY KEY,
    train_id INT NOT NULL REFERENCES subway_schema.train(train_id),
    employee_id INT NOT NULL REFERENCES subway_schema.employee(employee_id),
    date DATE NOT NULL CHECK (date > '2000-01-01')
);

CREATE TABLE IF NOT EXISTS subway_schema.employee_maintenance(
	employee_maintenance_id SERIAL PRIMARY KEY,
    maintenance_id INT NOT NULL REFERENCES subway_schema.maintenance(maintenance_id),
    employee_id INT NOT NULL REFERENCES subway_schema.employee(employee_id)
);

CREATE TABLE IF NOT EXISTS subway_schema.ticket(
	ticket_id SERIAL PRIMARY KEY,
    station_id INT NOT NULL REFERENCES subway_schema.station(station_id)
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
    cost_amount DECIMAL NOT NULL CHECK (cost_amount >= 0),
    ticket_id INT UNIQUE NOT NULL REFERENCES subway_schema.ticket(ticket_id),
    payment_date TIMESTAMP NOT NULL
);

--Added missing constraints 
ALTER TABLE subway_schema.payment
ADD CONSTRAINT check_payment_date
CHECK (payment_date < '2000-01-01');

ALTER TABLE subway_schema.employee_station
ADD CONSTRAINT check_payment_date
CHECK (payment_date < '2000-01-01');

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
--Adding data
-- Insert into subway_schema."object"
WITH new_objects AS (
    SELECT 'Station' AS object_type, 'Under Maintenance' AS status, '2024-11-10 04:00'::TIMESTAMP AS last_update
    UNION ALL 
    SELECT 'Train', 'Under Maintenance', '2024-11-10 04:00'::TIMESTAMP
    UNION ALL 
    SELECT 'Train', 'Under Maintenance', '2024-10-29 13:00'::TIMESTAMP
    UNION ALL 
    SELECT 'Train', 'Out of Service', '2024-10-29 04:00'::TIMESTAMP
    UNION ALL 
    SELECT 'Tunnel', 'Active', '2024-11-01 08:00'::TIMESTAMP
    UNION ALL 
    SELECT 'Station', 'Active', '2024-10-29 04:00'::TIMESTAMP
    UNION ALL 
    SELECT 'Tunnel', 'Active', '2024-11-10 04:10'::TIMESTAMP
    UNION ALL 
    SELECT 'Station', 'Active', '2024-10-29 04:00'::TIMESTAMP
), -- CTE for inserting new objects with checking on existing in database
inserted_objects AS (
    INSERT INTO subway_schema."object" (object_type, status, last_update)
    SELECT 
        nobj.object_type,
        nobj.status,
        nobj.last_update
    FROM 
        new_objects nobj
    RETURNING object_type, status, last_update
)
SELECT object_type, status, last_update FROM inserted_objects;

SELECT * FROM subway_schema."object" o ;
--TRUNCATE subway_schema."object" cascade;
--ALTER SEQUENCE subway_schema."object_object_id_seq" RESTART WITH 1;

-- Insert for subway_schema.subway_line
WITH new_subway_lines AS (
    SELECT 'Zhibek Zholy-Abay-Seyfulina-Almaly-Momyshuly-Alatau-Moscow' AS full_line,
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
    SELECT 'Zhibek Zholy' AS station_name, 'Zhibek Zholy 1' AS address, 1 AS object_id, 
    (SELECT sl.subway_line_id FROM subway_schema.subway_line sl 
   		 WHERE sl.full_line = 'Zhibek Zholy-Abay-Seyfulina-Almaly-Momyshuly-Alatau-Moscow') AS subway_line_id
    UNION ALL 
    SELECT 'Abay', 'Abay 57', 6,
		(SELECT sl.subway_line_id FROM subway_schema.subway_line sl 
   		 WHERE sl.full_line = 'Zhibek Zholy-Abay-Seyfulina-Almaly-Momyshuly-Alatau-Moscow')
    UNION ALL 
    SELECT 'Seyfulina', 'Seyfulina 22', 8, 
    	(SELECT sl.subway_line_id FROM subway_schema.subway_line sl 
   		 WHERE sl.full_line = 'Zhibek Zholy-Abay-Seyfulina-Almaly-Momyshuly-Alatau-Moscow')
)
INSERT INTO subway_schema.station (station_name, address, object_id, subway_line_id)
SELECT ns.station_name, ns.address, ns.object_id, ns.subway_line_id
FROM new_stations ns
WHERE NOT EXISTS (
    SELECT 1 FROM subway_schema.station s
    WHERE s.object_id = ns.object_id
);

SELECT * FROM subway_schema.station ;

-- Insert for subway_schema.train
WITH new_trains AS (
    SELECT 'TR001' AS serial_number, 
    	(SELECT sl.subway_line_id FROM subway_schema.subway_line sl 
   		 WHERE sl.full_line = 'Zhibek Zholy-Abay-Seyfulina-Almaly-Momyshuly-Alatau-Moscow') AS subway_line_id,
   		 800 AS capacity, 2 AS object_id
    UNION ALL 
    SELECT 'TR002', (SELECT sl.subway_line_id FROM subway_schema.subway_line sl 
   		 WHERE sl.full_line = 'Zhibek Zholy-Abay-Seyfulina-Almaly-Momyshuly-Alatau-Moscow'),
   		 1000, 3
    UNION ALL 
    SELECT 'TR003', 
    	(SELECT sl.subway_line_id FROM subway_schema.subway_line sl 
   		 WHERE sl.full_line = 'Zhibek Zholy-Abay-Seyfulina-Almaly-Momyshuly-Alatau-Moscow'),
   		 0, 4
)
INSERT INTO subway_schema.train (serial_number, subway_line_id, capacity, object_id)
SELECT nt.serial_number, nt.subway_line_id, nt.capacity, nt.object_id
FROM new_trains nt
WHERE NOT EXISTS (
    SELECT 1 FROM subway_schema.train t
    WHERE t.serial_number = nt.serial_number
);

SELECT * FROM subway_schema.train;

-- Insert for subway_schema.tunnel
WITH new_tunnels AS (
    SELECT 	
    	(SELECT sl.subway_line_id FROM subway_schema.subway_line sl 
   		 WHERE sl.full_line = 'Zhibek Zholy-Abay-Seyfulina-Almaly-Momyshuly-Alatau-Moscow') AS subway_line_id, 
    	(SELECT s.station_id FROM subway_schema.station s WHERE s.station_name = 'Zhibek Zholy') AS start_station_id, 
    	(SELECT s.station_id FROM subway_schema.station s WHERE s.station_name = 'Abay') AS end_station_id, 
    	  5 AS object_id
    UNION ALL 
    SELECT 
    	(SELECT sl.subway_line_id FROM subway_schema.subway_line sl 
   		WHERE sl.full_line = 'Zhibek Zholy-Abay-Seyfulina-Almaly-Momyshuly-Alatau-Moscow'), 
   		(SELECT s.station_id FROM subway_schema.station s WHERE s.station_name = 'Abay'),
  	    (SELECT s.station_id FROM subway_schema.station s WHERE s.station_name = 'Seyfulina'),
   	    7
)
INSERT INTO subway_schema.tunnel (subway_line_id, start_station_id, end_station_id, object_id)
SELECT nt.subway_line_id, nt.start_station_id, nt.end_station_id, nt.object_id
FROM new_tunnels nt
WHERE NOT EXISTS (
    SELECT 1 FROM subway_schema.tunnel t
    WHERE (t.start_station_id = nt.start_station_id 
      AND t.end_station_id = nt.end_station_id)
      OR t.object_id = nt.object_id
);

SELECT * FROM subway_schema.tunnel ;

-- Insert for subway_schema.schedule
WITH new_schedules AS (
    SELECT 
    	(SELECT s.station_id FROM subway_schema.station s WHERE s.station_name = 'Zhibek Zholy') AS station_id, 
    	(SELECT sl.subway_line_id FROM subway_schema.subway_line sl 
   		WHERE sl.full_line = 'Zhibek Zholy-Abay-Seyfulina-Almaly-Momyshuly-Alatau-Moscow') AS subway_line_id, 
    	(SELECT train_id FROM subway_schema.train WHERE serial_number = 'TR001') AS train_id, 
    	'08:00'::TIME AS arrival_time, 
    	'08:05'::TIME AS departure_time
    UNION ALL 
    SELECT 
    	(SELECT s.station_id FROM subway_schema.station s WHERE s.station_name = 'Abay') AS station_id, 
    	(SELECT sl.subway_line_id FROM subway_schema.subway_line sl 
   		WHERE sl.full_line = 'Zhibek Zholy-Abay-Seyfulina-Almaly-Momyshuly-Alatau-Moscow') AS subway_line_id, 
    	(SELECT train_id FROM subway_schema.train WHERE serial_number = 'TR001') AS train_id, 
    	'08:12'::TIME AS arrival_time, 
    	'08:17'::TIME AS departure_time
)
INSERT INTO subway_schema.schedule (station_id, subway_line_id, train_id, arrival_time, departure_time)
SELECT ns.station_id, ns.subway_line_id, ns.train_id, ns.arrival_time, ns.departure_time
FROM new_schedules ns
;

SELECT * FROM subway_schema.schedule;

-- Insert for subway_schema.maintenance
WITH new_maintenance AS (
    SELECT 3 AS object_id, 'Repair' AS maintenance_type, '2024-10-29 13:00'::TIMESTAMP AS start_time, NULL AS end_time
    UNION ALL 
    SELECT  5, 'scheduled inspection', '2024-11-01 06:00'::TIMESTAMP, '2024-11-01 08:00'::TIMESTAMP
    UNION ALL 
    SELECT  7, 'scheduled inspection', '2024-11-01 06:00'::TIMESTAMP, '2024-11-01 08:00'::TIMESTAMP
    UNION ALL 
    SELECT  2, 'scheduled inspection', '2024-11-02 04:00'::TIMESTAMP, '2024-11-02 06:00'::TIMESTAMP
    UNION ALL 
    SELECT  1, 'scheduled inspection', '2024-11-10 04:00'::TIMESTAMP, NULL
    UNION ALL 
    SELECT  2, 'Repair', '2024-11-10 04:00'::TIMESTAMP, NULL
    UNION ALL 
    SELECT  7, 'scheduled inspection', '2024-11-10 04:10'::TIMESTAMP, NULL
)
INSERT INTO subway_schema.maintenance (maintenance_id, object_id, maintenance_type, start_time, end_time)
SELECT nm.maintenance_id, nm.object_id, nm.maintenance_type, nm.start_time, nm.end_time
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
--I'm sorry. I didn't have time to finish the insert task.

SELECT * FROM subway_schema.employee;


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
