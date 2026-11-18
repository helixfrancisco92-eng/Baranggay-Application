# Owner Evidence Artifacts — Baseline & Diagnostics of Group 12 (iBarangay)

This directory stores evidence artifacts, schema inspection outputs, and baseline query logs collected by Group 12 for our own project (`Baranggay-Application` / `PPGG_projectdb`).

### Evidence Index:
1. `ibarangay_schema_catalog.txt`: Catalog output confirming all 7 tables and Flyway migrations (V1, V2, V3) in schema `public`.
2. `ibarangay_sequences_sync.txt`: Identity sequence audit output verifying that sequences are aligned with `MAX(id)`.
3. `ibarangay_rbac_matrix.txt`: `information_schema.table_privileges` output confirming least-privilege grants for `ibarangay_runtime_grp`.
4. `ibarangay_buffer_cache.txt`: Buffer cache hit ratio output confirming 99.85%+ memory efficiency.
