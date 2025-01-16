DO $$
BEGIN
    IF NOT EXISTS (
        SELECT FROM pg_database WHERE datname = 'Final_Task'
    ) THEN
        EXECUTE 'CREATE DATABASE Final_Task';
    END IF;
END $$;

CREATE SCHEMA IF NOT EXISTS museum_schema;

--Creating tables
--3. Create a physical database with a separate database and schema and give it an appropriate domain-related name.
--Create relationships between tables using primary and foreign keys.


CREATE TABLE IF NOT EXISTS museum_schema.category (
    category_id SERIAL PRIMARY KEY,
    "name" VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS museum_schema.art (
    art_id SERIAL PRIMARY KEY,
    "name" TEXT UNIQUE NOT NULL,
    category_id INT NOT NULL REFERENCES museum_schema.category(category_id),
    creation_year INT NOT NULL,
    description TEXT
);

CREATE TABLE IF NOT EXISTS museum_schema.artist (
    artist_id SERIAL PRIMARY KEY,
    "name" VARCHAR(50) NOT NULL,
    surname VARCHAR(50) NOT NULL,
    full_name VARCHAR(100) GENERATED ALWAYS AS ("name" || ' ' || surname) STORED,
    date_of_birth DATE NOT NULL,
    description TEXT
);

CREATE TABLE IF NOT EXISTS museum_schema.art_artist (
    art_artist_id SERIAL PRIMARY KEY,
    art_id INT NOT NULL REFERENCES museum_schema.art(art_id),
    artist_id INT NOT NULL REFERENCES museum_schema.artist(artist_id)
);

CREATE TABLE IF NOT EXISTS museum_schema.inventory (
    inventory_id SERIAL PRIMARY KEY,
    art_id INT NOT NULL UNIQUE REFERENCES museum_schema.art(art_id)
);

CREATE TABLE IF NOT EXISTS museum_schema.exhibition (
    exhibition_id SERIAL PRIMARY KEY,
    theme VARCHAR(50) NOT NULL,
    "type" VARCHAR(15) NOT NULL,
    event_date DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS museum_schema.exhibition_inventory (
    exhibition_inventory_id SERIAL PRIMARY KEY,
    inventory_id INT NOT NULL REFERENCES museum_schema.inventory(inventory_id),
    exhibition_id INT NOT NULL REFERENCES museum_schema.exhibition(exhibition_id),
    event_date DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS museum_schema.employee (
    employee_id SERIAL PRIMARY KEY,
    "name" VARCHAR(50) NOT NULL,
    surname VARCHAR(50) NOT NULL,
    full_name VARCHAR(100) GENERATED ALWAYS AS ("name" || ' ' || surname) STORED,
    role VARCHAR(30) NOT NULL,
    date_of_birth DATE NOT NULL,
    personal_id VARCHAR(12) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS museum_schema.employee_exhibition (
    employee_exhibition_id SERIAL PRIMARY KEY,
    exhibition_id INT NOT NULL REFERENCES museum_schema.exhibition(exhibition_id),
    employee_id INT NOT NULL REFERENCES museum_schema.employee(employee_id)
);

CREATE TABLE IF NOT EXISTS museum_schema.visitor (
    visitor_id SERIAL PRIMARY KEY,
    "name" VARCHAR(50) NOT NULL,
    surname VARCHAR(50) NOT NULL,
    full_name VARCHAR(100) GENERATED ALWAYS AS ("name" || ' ' || surname) STORED,
    personal_id VARCHAR(12) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS museum_schema.exhibition_visitor (
    exhibition_visitor_id SERIAL PRIMARY KEY,
    exhibition_id INT NOT NULL REFERENCES museum_schema.exhibition(exhibition_id),
    visitor_id INT NOT NULL REFERENCES museum_schema.visitor(visitor_id)
);

--Use ALTER TABLE to add at least 5 check constraints across the tables to restrict certain values
-- Deleting constraints that created by Alter table, for rerunability

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_art_date') THEN
        ALTER TABLE museum_schema.art DROP CONSTRAINT check_art_date;
    END IF;

    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_exhibition_date') THEN
        ALTER TABLE museum_schema.exhibition DROP CONSTRAINT check_exhibition_date;
    END IF;

    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_exhibition_inventory_date') THEN
        ALTER TABLE museum_schema.exhibition_inventory DROP CONSTRAINT check_exhibition_inventory_date;
    END IF;

    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_exhibition_type') THEN
        ALTER TABLE museum_schema.exhibition DROP CONSTRAINT check_exhibition_type;
    END IF;

    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_employee_personal_id') THEN
        ALTER TABLE museum_schema.employee DROP CONSTRAINT check_employee_personal_id;
    END IF;

	IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_visitor_personal_id') THEN
        ALTER TABLE museum_schema.visitor DROP CONSTRAINT check_visitor_personal_id;
    END IF;

    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'unique_exhibition_event_type') THEN
        ALTER TABLE museum_schema.exhibition DROP CONSTRAINT unique_exhibition_event_type;
    END IF;

    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'unique_exhibition_inventory') THEN
        ALTER TABLE museum_schema.exhibition_inventory DROP CONSTRAINT unique_exhibition_inventory;
    END IF;

    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'unique_exhibition_visitor') THEN
        ALTER TABLE museum_schema.exhibition_visitor DROP CONSTRAINT unique_exhibition_visitor;
    END IF;
	IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_creation_year') THEN
        ALTER TABLE museum_schema.art DROP CONSTRAINT check_creation_year;
    END IF;
END $$;

--Altering table with constarints

ALTER TABLE museum_schema.exhibition
ADD CONSTRAINT check_exhibition_date CHECK (event_date >= '2024-07-01');

ALTER TABLE museum_schema.exhibition_inventory
ADD CONSTRAINT check_exhibition_inventory_date CHECK (event_date >= '2024-07-01');

ALTER TABLE museum_schema.art
ADD CONSTRAINT check_creation_year CHECK (creation_year >=1000 AND creation_year <=2025);

ALTER TABLE museum_schema.exhibition
ALTER COLUMN event_date SET DEFAULT CURRENT_DATE;

ALTER TABLE museum_schema.exhibition_inventory
ALTER COLUMN event_date SET DEFAULT CURRENT_DATE;

ALTER TABLE museum_schema.art
ALTER COLUMN description SET DEFAULT NOT NULL;

ALTER TABLE museum_schema.artist
ALTER COLUMN description SET DEFAULT NOT NULL;

ALTER TABLE museum_schema.exhibition
ADD CONSTRAINT check_exhibition_type CHECK ("type" IN ('Online', 'Offline'));


ALTER TABLE museum_schema.employee
ADD CONSTRAINT check_employee_personal_id CHECK (personal_id ~ '^[0-9]+$');

ALTER TABLE museum_schema.visitor
ADD CONSTRAINT check_visitor_personal_id CHECK (personal_id ~ '^[0-9]+$');


ALTER TABLE museum_schema.exhibition
ADD CONSTRAINT unique_exhibition_event_type UNIQUE (event_date, "type");

ALTER TABLE museum_schema.exhibition_inventory
ADD CONSTRAINT unique_exhibition_inventory UNIQUE (exhibition_id, inventory_id);

ALTER TABLE museum_schema.art_artist
ADD CONSTRAINT unique_art_artist UNIQUE (art_id, artist_id);

ALTER TABLE museum_schema.exhibition_visitor
ADD CONSTRAINT unique_exhibition_visitor UNIQUE (exhibition_id, visitor_id);


--4. Populate the tables with the sample data generated, ensuring each table has
--at least 6+ rows (for a total of 36+ rows in all the tables) for the last 3 months.
--Inserting object
--CATEGORY
WITH new_categories AS (
    SELECT 'Painting' AS "name"
    UNION ALL
    SELECT 'Artifacts'
    UNION ALL
    SELECT 'Antiques'
    UNION ALL
    SELECT 'Historical objects'
    UNION ALL
    SELECT 'Specimens'
    UNION ALL
    SELECT 'Modern Art'
), inserted_categories AS (
    INSERT INTO museum_schema.category ("name")
    SELECT "name"
    FROM new_categories nc
    WHERE NOT EXISTS (
        SELECT 1
        FROM museum_schema.category c
        WHERE c."name" = nc."name"
    )
    RETURNING category_id, "name"
) SELECT * FROM inserted_categories;

-- SELECT * FROM museum_schema.category c ;

-- ART
WITH new_art AS (
    SELECT 'Impression, Sunrise' AS "name",
    (SELECT category_id FROM museum_schema.category WHERE lower("name")='painting') AS category_id,
    1867 AS creation_year, 'Impression, Sunrise captures a quiet morning in the port of Le Havre.' AS description
    UNION ALL
    SELECT 'The Starry Night',
    (SELECT category_id FROM museum_schema.category WHERE lower("name")='painting'),
    1889, 'A famous painting by Vincent van Gogh'
    UNION ALL
    SELECT 'The Big Wave off Kanagawa',
    (SELECT category_id FROM museum_schema.category WHERE lower("name")='painting'),
    1831, 'A story of a never-ending process in life where once we have conquered our fear and get what we want, we will be met again with other vicious waves, other bigger problems, and difficulties.'
    UNION ALL
    SELECT 'Altyn Adam',
    (SELECT category_id FROM museum_schema.category WHERE lower("name")='artifacts'),
    1969, 'Founded in Kazakhstan'
    UNION ALL
    SELECT 'The Pinner Qing Dynasty Vase',
    (SELECT category_id FROM museum_schema.category WHERE lower("name")='antiques'),
    1700, 'Very Expensive, sold for 80 million dollars'
    UNION ALL
    SELECT 'Leonardo da Vinci’s Codex Leicester',
    (SELECT category_id FROM museum_schema.category WHERE lower("name")='antiques'),
    1500, 'Leonardo da Vinci’s Codex Leicester, a collection of scientific writings and sketches, is another highly valued antique.'
    UNION ALL
    SELECT 'Almond Blossoms',
    (SELECT category_id FROM museum_schema.category WHERE lower("name")='painting'),
    1889, ' In Van Gogh''s personal symbolism, these flowers represented hope, renewal, and the cycle of life.'
), inserted_art AS (
    INSERT INTO museum_schema.art (name, category_id, creation_year, description)
    SELECT "name", category_id, creation_year, description
    FROM new_art na
    WHERE NOT EXISTS (
        SELECT 1
        FROM museum_schema.art a
        WHERE a."name" = na."name"
    )
    RETURNING art_id, "name", category_id, description
)
SELECT * FROM inserted_art;

-- SELECT * FROM museum_schema.art a ;

--ARTISTS
WITH new_artists AS (
    SELECT 'Leonardo' AS "name", 'da Vinci' AS surname, '1452-04-15'::date AS date_of_birth, 'Italian polymath' AS description
    UNION ALL
    SELECT 'Dias', 'Yermekov', '2002-11-14'::date, 'Some biography, found in Internet The Pinner Qing Dynasty Vase without creator or founder'
    UNION ALL
    SELECT 'Vincent', 'van Gogh', '1853-03-30'::date, 'Dutch post-impressionist painter'
    UNION ALL
    SELECT 'Claude', 'Monet', '1840-11-14'::date, 'Claude Monet was a French painter and founder of impressionism painting'
    UNION ALL
    SELECT 'Hokusai', 'Katsushika', '1760-10-31'::date, 'Japanese ukiyo-e painter and printmaker'
    UNION ALL
    SELECT 'Kemal', 'Akishevab', '1925-05-25'::date, 'The archaeologist'
), inserted_artists AS (
    INSERT INTO museum_schema.artist ("name", surname, date_of_birth, description)
    SELECT "name", surname, date_of_birth, description
    FROM new_artists na
    WHERE NOT EXISTS (
        SELECT 1
        FROM museum_schema.artist a
        WHERE a."name" = na."name" AND a.surname = na.surname
    )
    RETURNING "name", surname, date_of_birth, description
)
SELECT * FROM inserted_artists;

-- SELECT * FROM museum_schema.artist a ;

--ART_ARTIST
WITH new_art_artist AS (
    SELECT (SELECT art_id FROM museum_schema.art WHERE lower("name")='impression, sunrise') AS art_id,
    (SELECT artist_id FROM museum_schema.artist WHERE lower("full_name")='claude monet') AS artist_id
    UNION ALL
    SELECT (SELECT art_id FROM museum_schema.art WHERE lower("name")='the starry night'),
    (SELECT artist_id FROM museum_schema.artist WHERE lower("full_name")='vincent van gogh')
    UNION ALL
    SELECT (SELECT art_id FROM museum_schema.art WHERE lower("name")='almond blossoms'),
    (SELECT artist_id FROM museum_schema.artist WHERE lower("full_name")='vincent van gogh')
    UNION ALL
    SELECT (SELECT art_id FROM museum_schema.art WHERE lower("name")='the big wave off kanagawa'),
    (SELECT artist_id FROM museum_schema.artist WHERE lower("full_name")='hokusai katsushika')
    UNION ALL
    SELECT (SELECT art_id FROM museum_schema.art WHERE lower("name")=lower('Leonardo da Vinci’s Codex Leicester')),
    (SELECT artist_id FROM museum_schema.artist WHERE lower("full_name")='leonardo da vinci')
    UNION ALL
    SELECT (SELECT art_id FROM museum_schema.art WHERE lower("name")=lower('The Pinner Qing Dynasty Vase')),
    (SELECT artist_id FROM museum_schema.artist WHERE lower("full_name")='dias yermekov')
    UNION ALL
    SELECT (SELECT art_id FROM museum_schema.art WHERE lower("name")='altyn adam'),
    (SELECT artist_id FROM museum_schema.artist WHERE lower("full_name")='kemal akishevab')
), inserted_art_artist AS (
    INSERT INTO museum_schema.art_artist (art_id, artist_id)
    SELECT art_id, artist_id
    FROM new_art_artist naa
    WHERE NOT EXISTS (
        SELECT 1
        FROM museum_schema.art_artist aa
        WHERE aa.art_id = naa.art_id
          AND aa.artist_id = naa.artist_id
    )
    RETURNING art_artist_id, art_id, artist_id
)
SELECT * FROM inserted_art_artist;

-- SELECT * FROM museum_schema.art_artist aa ;

-- INVENTORY
WITH new_invetories AS (
    SELECT (SELECT art_id FROM museum_schema.art WHERE lower("name") = lower('The Starry Night')) AS art_id
    UNION ALL
    SELECT (SELECT art_id FROM museum_schema.art WHERE lower("name") = lower('Impression, Sunrise'))
    UNION ALL
    SELECT (SELECT art_id FROM museum_schema.art WHERE lower("name") = lower('The Big Wave off Kanagawa'))
    UNION ALL
    SELECT (SELECT art_id FROM museum_schema.art WHERE lower("name") = lower('Altyn Adam'))
    UNION ALL
    SELECT (SELECT art_id FROM museum_schema.art WHERE lower("name") = lower('Leonardo da Vinci’s Codex Leicester'))
    UNION ALL
    SELECT (SELECT art_id FROM museum_schema.art WHERE lower("name") = lower('Almond Blossoms'))
), inserted_inventory AS (
    INSERT INTO museum_schema.inventory (art_id)
    SELECT art_id FROM new_invetories ni
    WHERE NOT EXISTS (SELECT 1 FROM museum_schema.inventory i
                      WHERE i.art_id = ni.art_id)
    RETURNING art_id
)
SELECT * FROM inserted_inventory;

-- SELECT * FROM museum_schema.inventory i ;

--Exhibition
WITH new_exhibitions AS (
    SELECT 'Paintings' AS theme, 'Offline' AS "type", '2024-12-01'::date AS event_date
    UNION ALL
    SELECT 'Artifacts', 'Online', '2024-09-01'::date
    UNION ALL
    SELECT 'Antiques', 'Offline', '2024-12-02'::date
    UNION ALL
    SELECT 'Artifacts', 'Online', '2024-11-30'::date
    UNION ALL
    SELECT 'Leonardo da Vinci', 'Online', '2024-12-02'::date
    UNION ALL
    SELECT 'Antiques', 'Offline', '2024-09-12'::date
), inserted_exhibitions AS (
    INSERT INTO museum_schema.exhibition (theme, "type", event_date)
    SELECT theme, "type", event_date
    FROM new_exhibitions ne
    WHERE NOT EXISTS (
        SELECT 1
        FROM museum_schema.exhibition e
        WHERE e."type" = ne."type" AND e.event_date = ne.event_date
    ) ORDER BY event_date ASC
    RETURNING exhibition_id, theme, "type", event_date
)
SELECT * FROM inserted_exhibitions;

-- SELECT * FROM museum_schema.exhibition e ;

--Exhibition inventory
WITH new_exhibition_inventory AS (
-- Artifacts 2024-11-30
    SELECT
    	(SELECT exhibition_id FROM museum_schema.exhibition WHERE "type" = 'Online' AND event_date = '2024-11-30'::date) AS exhibition_id,
    	(SELECT inventory_id FROM museum_schema.inventory
                WHERE art_id = (SELECT art_id FROM museum_schema.art WHERE lower("name") = lower('Altyn Adam'))) AS inventory_id,
    	(SELECT event_date FROM museum_schema.exhibition WHERE "type" = 'Online' AND event_date = '2024-11-30'::date) AS event_date
-- Paintings 2024-12-01
     UNION ALL
     SELECT
         (SELECT exhibition_id FROM museum_schema.exhibition WHERE "type" = 'Offline' AND event_date = '2024-12-01'::date),
         (SELECT inventory_id FROM museum_schema.inventory
                WHERE art_id = (SELECT art_id FROM museum_schema.art WHERE lower("name") = lower('The Starry Night'))),
         (SELECT event_date FROM museum_schema.exhibition WHERE "type" = 'Offline' AND event_date = '2024-12-01'::date)
     UNION ALL
     SELECT
         (SELECT exhibition_id FROM museum_schema.exhibition WHERE "type" = 'Offline' AND event_date = '2024-12-01'::date),
         (SELECT inventory_id FROM museum_schema.inventory
                WHERE art_id = (SELECT art_id FROM museum_schema.art WHERE lower("name") = lower('Impression, Sunrise'))),
         (SELECT event_date FROM museum_schema.exhibition WHERE "type" = 'Offline' AND event_date = '2024-12-01'::date)
     UNION ALL
     SELECT
         (SELECT exhibition_id FROM museum_schema.exhibition WHERE "type" = 'Offline' AND event_date = '2024-12-01'::date),
         (SELECT inventory_id FROM museum_schema.inventory
                WHERE art_id = (SELECT art_id FROM museum_schema.art WHERE lower("name") = lower('The Big Wave off Kanagawa'))),
         (SELECT event_date FROM museum_schema.exhibition WHERE "type" = 'Offline' AND event_date = '2024-12-01'::date)
     UNION ALL
     SELECT
         (SELECT exhibition_id FROM museum_schema.exhibition WHERE "type" = 'Offline' AND event_date = '2024-12-01'::date),
         (SELECT inventory_id FROM museum_schema.inventory
                WHERE art_id = (SELECT art_id FROM museum_schema.art WHERE lower("name") = lower('Almond Blossoms'))),
         (SELECT event_date FROM museum_schema.exhibition WHERE "type" = 'Offline' AND event_date = '2024-12-01'::date)
--    --Leonardo da Vinci 2024-12-02
     UNION ALL
     SELECT
         (SELECT exhibition_id FROM museum_schema.exhibition WHERE "type" = 'Online' AND event_date = '2024-12-02'::date),
         (SELECT inventory_id FROM museum_schema.inventory
                WHERE art_id =
         (SELECT art_id FROM museum_schema.art_artist aa JOIN museum_schema.artist ast USING(artist_id) JOIN museum_schema.art using(art_id)
         WHERE lower(art."name") = lower('Leonardo da Vinci’s Codex Leicester')
         AND lower(ast.full_name) = lower('Leonardo da Vinci'))),  --implemented only FOR this line
         (SELECT event_date FROM museum_schema.exhibition WHERE "type" = 'Online' AND event_date = '2024-12-02'::date)
--     -- Antiques 2024-12-02
     UNION ALL
     SELECT
        (SELECT exhibition_id FROM museum_schema.exhibition WHERE "type" = 'Offline' AND event_date = '2024-12-02'::date) AS exhibition_id,
        (SELECT inventory_id FROM museum_schema.inventory
                WHERE art_id = (SELECT art_id FROM museum_schema.art WHERE lower("name") = lower('Leonardo da Vinci’s Codex Leicester'))),
        (SELECT event_date FROM museum_schema.exhibition WHERE "type" = 'Offline' AND event_date = '2024-12-02'::date) AS event_date
), inserted_exhibition_inventory AS (
    INSERT INTO museum_schema.exhibition_inventory (exhibition_id, inventory_id, event_date)
    SELECT exhibition_id, inventory_id, event_date
    FROM new_exhibition_inventory nei
    WHERE NOT EXISTS (
        SELECT 1
        FROM museum_schema.exhibition_inventory ei
          WHERE ei.exhibition_id = nei.exhibition_id
          AND ei.inventory_id = nei.inventory_id
          AND ei.event_date = nei.event_date
    ) ORDER BY event_date
    RETURNING inventory_id, exhibition_id, event_date
)
SELECT * FROM inserted_exhibition_inventory;

-- SELECT * FROM museum_schema.exhibition_inventory ei;

SELECT * FROM museum_schema.inventory JOIN museum_schema.art using(art_id);

--EMPLOYEE
WITH new_employees AS (
    SELECT 'John' AS "name", 'Doe' AS surname, 'Curator' AS role, '1980-03-15'::date AS date_of_birth, '123456789012' AS personal_id
    UNION ALL
    SELECT 'Jane', 'Smith', 'Security', '1990-07-22'::date, '234567890123'
    UNION ALL
    SELECT 'Sam', 'Brown', 'Guide', '1995-06-10'::date, '345678901234'
    UNION ALL
    SELECT 'Emily', 'Johnson', 'Manager', '1985-04-05'::date, '456789012345'
    UNION ALL
    SELECT 'Michael', 'Davis', 'Guide', '1992-02-18'::date, '567890123456'
    UNION ALL
    SELECT 'Sarah', 'Wilson', 'Designer', '1988-11-25'::date, '678901234567'
),
filtered_visitors AS ( -- checking uniqueness OF person ids among tables
    SELECT *
    FROM new_employees ne
    WHERE NOT EXISTS (
        SELECT 1
        FROM museum_schema.visitor v
        WHERE ne.personal_id = v.personal_id
    )
),
inserted_employees AS (
    INSERT INTO museum_schema.employee ("name", surname, role, date_of_birth, personal_id)
    SELECT "name", surname, role, date_of_birth, personal_id
    FROM new_employees ne
    WHERE NOT EXISTS (
        SELECT 1
        FROM museum_schema.employee e
        WHERE e.personal_id = ne.personal_id
    )
    RETURNING "name", surname, ROLE, date_of_birth, personal_id
)
SELECT * FROM inserted_employees;

-- SELECT * FROM museum_schema.employee;

--EMPLOYEE EXHIBITION
WITH new_employee_exhibition AS (
    SELECT (SELECT exhibition_id FROM museum_schema.exhibition WHERE event_date = '2024-12-02'::date AND lower("type") = lower('Offline')) AS exhibition_id,
    (SELECT employee_id FROM museum_schema.employee WHERE personal_id = '678901234567') AS employee_id
    UNION ALL
    SELECT (SELECT exhibition_id FROM museum_schema.exhibition WHERE event_date = '2024-12-02'::date AND lower("type") = lower('Online')),
    (SELECT employee_id FROM museum_schema.employee WHERE personal_id = '678901234567')
    UNION ALL
    SELECT (SELECT exhibition_id FROM museum_schema.exhibition WHERE event_date = '2024-12-02'::date AND lower("type") = lower('Offline')),
    (SELECT employee_id FROM museum_schema.employee WHERE personal_id = '456789012345')
    UNION ALL
    SELECT (SELECT exhibition_id FROM museum_schema.exhibition WHERE event_date = '2024-12-02'::date AND lower("type") = lower('Offline')),
    (SELECT employee_id FROM museum_schema.employee WHERE personal_id = '234567890123')
    UNION ALL
    SELECT (SELECT exhibition_id FROM museum_schema.exhibition WHERE event_date = '2024-12-02'::date AND lower("type") = lower('Offline')),
    (SELECT employee_id FROM museum_schema.employee WHERE personal_id = '567890123456')
    UNION ALL
    SELECT (SELECT exhibition_id FROM museum_schema.exhibition WHERE event_date = '2024-12-02'::date AND lower("type") = lower('Online')),
    (SELECT employee_id FROM museum_schema.employee WHERE personal_id = '345678901234')
), inserted_employee_exhibition AS (
    INSERT INTO museum_schema.employee_exhibition (exhibition_id, employee_id)
    SELECT exhibition_id, employee_id
    FROM new_employee_exhibition
    WHERE NOT EXISTS (
        SELECT 1
        FROM museum_schema.employee_exhibition ee
        WHERE ee.exhibition_id = new_employee_exhibition.exhibition_id
          AND ee.employee_id = new_employee_exhibition.employee_id
    ) ORDER BY exhibition_id
    RETURNING exhibition_id, employee_id
)
SELECT * FROM inserted_employee_exhibition;

-- SELECT * FROM museum_schema.employee_exhibition;

--VISITORS
WITH new_visitors AS (
    SELECT 'Alice' AS "name", 'Adams' AS surname, '789012345678' AS personal_id
    UNION ALL
    SELECT 'Bob', 'Baker', '890123456789'
    UNION ALL
    SELECT 'Charlie', 'Chaplin', '901234567890'
    UNION ALL
    SELECT 'David', 'Duncan', '234565890123'
    UNION ALL
    SELECT 'Eva', 'Edwards', '345678701234'
    UNION ALL
    SELECT 'Frank', 'Foster', '456789032345'
),
filtered_visitors AS (
    SELECT *
    FROM new_visitors nv
    WHERE NOT EXISTS (
        SELECT 1
        FROM museum_schema.employee e
        WHERE e.personal_id = nv.personal_id
    )
),
inserted_visitors AS (
    INSERT INTO museum_schema.visitor ("name", surname, personal_id)
    SELECT "name", surname, personal_id
    FROM filtered_visitors fv
    WHERE NOT EXISTS (
        SELECT 1
        FROM museum_schema.visitor v
        WHERE v.personal_id = fv.personal_id
    )
    RETURNING "name", surname, personal_id
)
SELECT * FROM inserted_visitors;

-- SELECT * FROM museum_schema.visitor;

--VISITOR EXHIBITION

WITH new_exhibition_visitor AS (
    SELECT (SELECT exhibition_id FROM museum_schema.exhibition WHERE event_date = '2024-12-01'::date AND lower("type") = lower('Offline')) AS exhibition_id,
    (SELECT visitor_id FROM museum_schema.visitor WHERE personal_id = '890123456789') AS visitor_id
    UNION ALL
    SELECT (SELECT exhibition_id FROM museum_schema.exhibition WHERE event_date = '2024-12-02'::date AND lower("type") = lower('Online')),
    (SELECT visitor_id FROM museum_schema.visitor WHERE personal_id = '789012345678')
    UNION ALL
    SELECT (SELECT exhibition_id FROM museum_schema.exhibition WHERE event_date = '2024-12-02'::date AND lower("type") = lower('Offline')),
    (SELECT visitor_id FROM museum_schema.visitor WHERE personal_id = '901234567890')
    UNION ALL
    SELECT (SELECT exhibition_id FROM museum_schema.exhibition WHERE event_date = '2024-12-02'::date AND lower("type") = lower('Offline')),
    (SELECT visitor_id FROM museum_schema.visitor WHERE personal_id = '456789032345')
    UNION ALL
    SELECT (SELECT exhibition_id FROM museum_schema.exhibition WHERE event_date = '2024-12-02'::date AND lower("type") = lower('Offline')),
    (SELECT visitor_id FROM museum_schema.visitor WHERE personal_id = '234565890123')
    UNION ALL
    SELECT (SELECT exhibition_id FROM museum_schema.exhibition WHERE event_date = '2024-12-02'::date AND lower("type") = lower('Online')),
    (SELECT visitor_id FROM museum_schema.visitor WHERE personal_id = '345678701234')
), inserted_exhibition_visitor AS (
    INSERT INTO museum_schema.exhibition_visitor (exhibition_id, visitor_id)
    SELECT exhibition_id, visitor_id
    FROM new_exhibition_visitor
    WHERE NOT EXISTS (
        SELECT 1
        FROM museum_schema.exhibition_visitor ev
        WHERE ev.exhibition_id = new_exhibition_visitor.exhibition_id
          AND ev.visitor_id = new_exhibition_visitor.visitor_id
    ) ORDER BY exhibition_id
    RETURNING exhibition_id, visitor_id
)
SELECT * FROM inserted_exhibition_visitor;

--5. Create the following functions.
--5.1 Create a function that updates data in one of your tables. This function should take the following input arguments:
CREATE OR REPLACE FUNCTION museum_schema.update_art_column(
    art_id INT,
    upd_column_name TEXT,
    new_value TEXT
)
RETURNS VOID AS $$
DECLARE affected_rows INT;
BEGIN
	--check for existing column_name
	IF NOT EXISTS (
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = 'museum_schema'
          AND table_name = 'art'
          AND column_name = upd_column_name
    ) THEN
        RAISE NOTICE 'Column "%" does not exist in table "art".', upd_column_name;
        RETURN;
    END IF;

	--Updating table
    EXECUTE format('UPDATE museum_schema.art SET %I = $1 WHERE art_id = $2', upd_column_name)
    USING new_value, art_id;

	-- Get the number of affected rows
    GET DIAGNOSTICS affected_rows = ROW_COUNT;

    -- Check if any row was affected
    IF affected_rows = 0 THEN
        RAISE NOTICE 'No row found with art_id = %', art_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

--DROP FUNCTION museum_schema.update_art_column(bigint,text,text);

SELECT museum_schema.update_art_column(
    (SELECT art_id FROM museum_schema.art a WHERE lower("name") = lower('Altyn Adam')),
    'description',
    'Founded in Kazkahstan, famouus thing'
);
SELECT * FROM museum_schema.art a ;

--6. Create a view that presents analytics for the most recently added quarter in your database.
--Ensure that the result excludes irrelevant fields such as surrogate keys and duplicate entries.
--DROP VIEW IF EXISTS museum_schema.for_manual_analytics_recent_quarter;
--Through this view we can get analysis by each exhibitions and other.
CREATE OR REPLACE VIEW museum_schema.analytics_recent_quarter AS
SELECT
    e.theme AS exhibition_theme,
    e."type" AS exhibition_type,
    ei.event_date AS exhibition_date,
    EXTRACT(QUARTER FROM ei.event_date) AS quarter,
    a."name" AS art_name,
    c."name" AS category_name,
    ar.full_name AS artist_name,
    v.full_name AS visitor_name
FROM
    museum_schema.exhibition e
LEFT JOIN
    museum_schema.exhibition_inventory ei ON e.exhibition_id = ei.exhibition_id
LEFT JOIN
    museum_schema.inventory i ON ei.inventory_id = i.inventory_id
LEFT JOIN
    museum_schema.art a ON i.art_id = a.art_id
LEFT JOIN
    museum_schema.category c ON a.category_id = c.category_id
LEFT JOIN
    museum_schema.art_artist aa ON a.art_id = aa.art_id
LEFT JOIN
    museum_schema.artist ar ON aa.artist_id = ar.artist_id
LEFT JOIN
    museum_schema.exhibition_visitor ev ON e.exhibition_id = ev.exhibition_id
LEFT JOIN
    museum_schema.visitor v ON ev.visitor_id = v.visitor_id
WHERE
    EXTRACT(YEAR FROM ei.event_date) = EXTRACT(YEAR FROM CURRENT_DATE) AND
    EXTRACT(QUARTER FROM ei.event_date) = EXTRACT(QUARTER FROM CURRENT_DATE);

-- Views that gets total counts of exhibitions and visitors in quarter
CREATE OR REPLACE VIEW museum_schema.total_results_of_quarter AS
SELECT
    COUNT(DISTINCT (e.event_date, e."type")) AS total_exhibitions,
    COUNT(v.full_name) AS total_vistors
FROM
    museum_schema.exhibition e
LEFT JOIN
    museum_schema.exhibition_visitor ev ON e.exhibition_id = ev.exhibition_id
LEFT JOIN
    museum_schema.visitor v ON ev.visitor_id = v.visitor_id
WHERE
    EXTRACT(YEAR FROM e.event_date) = EXTRACT(YEAR FROM CURRENT_DATE) AND
    EXTRACT(QUARTER FROM e.event_date) = EXTRACT(QUARTER FROM CURRENT_DATE);

SELECT * FROM museum_schema.analytics_recent_quarter;
SELECT * FROM museum_schema.total_results_of_quarter;

--7. Create a read-only role for the manager. This role should have permission to perform SELECT queries on the database tables, and also be able to log in.
--Please ensure that you adhere to best practices for database security when defining this role

--Creating role
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'manager_read_only') THEN
        CREATE ROLE manager_read_only LOGIN PASSWORD 'secret_password';
    END IF;
END $$;

-- Grant CONNECT to the database
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_user WHERE usename = 'manager_read_only') THEN
        GRANT CONNECT ON DATABASE Final_Task TO manager_read_only;
    END IF;
END $$;

--Granting SELECT all tables
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.role_table_grants
                   WHERE grantee = 'manager_read_only'
                   AND table_schema = 'museum_schema'
                   AND privilege_type = 'SELECT') THEN
		GRANT USAGE ON SCHEMA museum_schema TO manager_read_only;
        GRANT SELECT ON ALL TABLES IN SCHEMA museum_schema TO manager_read_only;
    END IF;
END $$;

SET ROLE manager_read_only;
SELECT current_user;

--Checking for select privilige

SELECT art_id, "name", category_id, creation_year, description FROM museum_schema.art;
SELECT art_artist_id, art_id, artist_id FROM museum_schema.art_artist;
SELECT artist_id, "name", surname, full_name, date_of_birth, description FROM museum_schema.artist;
--SELECT category_id, "name" FROM museum_schema.category;
--SELECT employee_id, "name", surname, full_name, "role", date_of_birth, personal_id FROM museum_schema.employee;
--SELECT employee_exhibition_id, exhibition_id, employee_id FROM museum_schema.employee_exhibition;
--SELECT exhibition_id, theme, "type", event_date FROM museum_schema.exhibition;
--SELECT exhibition_inventory_id, inventory_id, exhibition_id, event_date FROM museum_schema.exhibition_inventory;
--SELECT exhibition_visitor_id, exhibition_id, visitor_id FROM museum_schema.exhibition_visitor;
--SELECT inventory_id, art_id FROM museum_schema.inventory;
--SELECT visitor_id, "name", surname, full_name, personal_id FROM museum_schema.visitor;
