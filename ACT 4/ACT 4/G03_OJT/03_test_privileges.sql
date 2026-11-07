SELECT * FROM your_actual_rma_table;

UPDATE your_actual_rma_table
SET status = 'Approved'
WHERE id = 1;

CREATE DATABASE unauthorized_test;


----------------------------

SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_type = 'BASE TABLE'
  AND table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY table_schema, table_name;