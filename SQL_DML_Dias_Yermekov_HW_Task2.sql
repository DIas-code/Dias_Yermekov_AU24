--1. Create table ‘table_to_delete’ and fill it with the following query:

CREATE TABLE table_to_delete AS
SELECT
	'veeeeeeery_long_string' || x AS col
FROM
	generate_series(1,
	(10 ^7)::int) x;

DROP TABLE table_to_delete;
-- generate_series() creates 10^7 rows of sequential numbers from 1 to 10000000 (10^7)

--2. Lookup how much space this table consumes with the following query:

SELECT
	*,
	pg_size_pretty(total_bytes) AS total,
	pg_size_pretty(index_bytes) AS INDEX,
	pg_size_pretty(toast_bytes) AS toast,
	pg_size_pretty(table_bytes) AS TABLE
FROM
	(
	SELECT
		*,
		total_bytes-index_bytes-COALESCE(toast_bytes,
		0) AS table_bytes
	FROM
		(
		SELECT
			c.oid,
			nspname AS table_schema,
			relname AS TABLE_NAME,
			c.reltuples AS row_estimate,
			pg_total_relation_size(c.oid) AS total_bytes,
			pg_indexes_size(c.oid) AS index_bytes,
			pg_total_relation_size(reltoastrelid) AS toast_bytes
		FROM
			pg_class c
		LEFT JOIN pg_namespace n ON
			n.oid = c.relnamespace
		WHERE
			relkind = 'r'
		) a
	) a
WHERE
	table_name LIKE '%table_to_delete%';

--3. Issue the following DELETE operation on ‘table_to_delete’:

DELETE FROM table_to_delete
WHERE REPLACE(col, 'veeeeeeery_long_string','')::int % 3 = 0; -- removes 1/3 of all rows

---a) Note how much time it takes to perform this DELETE statement; 17 second
---b) Lookup how much space this table consumes after previous DELETE;
--c) Perform the following command (if you're using DBeaver, press Ctrl+Shift+O to observe server output (VACUUM results)): 
VACUUM FULL VERBOSE table_to_delete;
--d) Check space consumption of the table once again and make conclusions;
--e) Recreate ‘table_to_delete’ table;

--4. Issue the following TRUNCATE operation:

TRUNCATE table_to_delete;
--a) Note how much time it takes to perform this TRUNCATE statement. <1 second
--b) Compare with previous results and make conclusion.
--c) Check space consumption of the table once again and make conclusions;


--5. Hand over your investigation's results to your trainer. The results must include:

--a) Space consumption of ‘table_to_delete’ table before and after each operation;
--b) Duration of each operation (DELETE, TRUNCATE) 
/*a) So, The DELETE operation in PostgreSQL has a safeguard in the form of the VACUUM command, if not commited. 
When data is deleted, it is only marked for deletion rather than being immediately removed. 
The VACUUM command is responsible for cleaning up and permanently removing the data that has been marked for deletion and taking space.*/

--Space before delete
--575 MB	0 bytes	8192 bytes	575 MB

-- After delete (Nothing happens, because after deletion, the data is marked as to be deleted, 
--and it can be returned by rollback in transaction if not commited)
--575 MB	0 bytes	8192 bytes	575 MB

--After VACUUM FULL VERBOSE (cleaning datas that marked on delete command, performing the actual removal)
--383 MB	0 bytes	8192 bytes	383 MB

/* 
TRUNCATE is a very fast way to remove all rows from a table.
But TRUNCATE less secure as it is much easier to lose all data.
Unlike the DELETE command, TRUNCATE does not mark rows for deletion; instead, 
it immediately removes all rows from the table without logging individual row deletions. 
This makes TRUNCATE significantly faster than DELETE for large tables. 
Additionally, TRUNCATE resets any associated sequences to their starting values, which is not the case with DELETE.
*/

--Space before TRUCATE
--575 MB	0 bytes	8192 bytes	575 MB

-- After TRUNCATE (All data deleted, without)
--8192 bytes	0 bytes	8192 bytes	0 bytes
--b) for DELETE 17 seconds and for TRUNCATE < 1 SECOND.