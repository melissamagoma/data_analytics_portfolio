# SQL Samples

Snowflake SQL written for a support analytics data warehouse at a SaaS company. These queries power executive reporting, product dashboards, and customer issue tracking used by VP, E-Group, CTO, CIO, and product teams.

The underlying model follows a dimensional pattern: fact tables for ticket events, dimension tables for attributes, and mart tables for pre-joined product metadata. Schema names have been anonymised.

---

## Queries

| File | What it does | Audience |
|---|---|---|
| [01_ticket_product_enrichment.sql](./01_ticket_product_enrichment.sql) | Bridges the product attribution gap by joining ticket data to linked issue metadata, producing a unified table of ticket metrics (RWT, MTTR, CES) alongside product group, stage, and category | CTO, CIO, Product teams, Support Engineering team |
| [02_tag_parsing_issue_reconstruction.sql](./02_tag_parsing_issue_reconstruction.sql) | Parses ticket tag strings to extract linked issue and MR references, reconstructs full URLs, and enriches each with product metadata and ticket counts — powers the weekly Customer Encountered Issues (CEI) report tracking top bugs, open issues, and product area distribution shared with product teams | Internal analytics, CTO, CIO, Product teams, Support Engineering team |
| [03_wow_report_base.sql](./03_wow_report_base.sql) | Pulls engineering-involved tickets with RWT and MTTR by product group and category — powers the weekly Support Bulletin, WoW report, and Tableau dashboards used by product teams to monitor support load by product area | VP, E-Group, Support Engineering team |
