# SQL Samples

Snowflake SQL queries written against a support analytics data warehouse. Schema names have been anonymized; logic and structure are unchanged.

The underlying data model follows a dimensional warehouse pattern: fact tables for ticket events, dimension tables for ticket attributes, and mart tables for pre-joined product metadata.

---

## Queries

| File | What it does |
|---|---|
| [01_ticket_product_enrichment.sql](./01_ticket_product_enrichment.sql) | Joins ticket data to product issue metadata with dynamic week-over-week date flags |
| [02_tag_parsing_issue_reconstruction.sql](./02_tag_parsing_issue_reconstruction.sql) | Parses raw ticket tag strings to extract and reconstruct linked GitLab issue and MR URLs |
| [03_wow_report_base.sql](./03_wow_report_base.sql) | Modular WoW reporting query covering tag-based link rate, form segmentation, and docs/handbook linkage |
