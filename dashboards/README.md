# Dashboards

Production Tableau dashboards built for a B2B SaaS support engineering team, following internal data governance standards. Built on Snowflake via certified dbt models and maintained in a production Tableau environment with role-based access controls.

---

## Support Single Pane of Glass (SPOG) Dashboard

**Audience:** Support Engineering leadership, VP-level stakeholders
**Refresh cadence:** Daily
**Data source:** Snowflake (ticketing system fact tables via certified dbt production models)

### What it does

Consolidates eight support KPIs into a single view so leadership can assess overall support health without switching between reports. Before this dashboard existed, these metrics lived across four separate Tableau workbooks with no shared filtering.

### Metrics covered

| Metric | Description |
|---|---|
| Incoming Ticket Volume | Monthly ticket creation count |
| FRT SLA Attainment | % of tickets receiving a first reply within SLA, stacked by within/outside |
| Customer Wait Time Ratio | % of resolution time spent waiting on the customer |
| Total Link Rate | % of tickets linked to an engineering issue or MR |
| Engineering Involvement Rate | % of tickets that required engineering escalation |
| AVG CES Score | Average Customer Effort Score (1–7 scale) |
| Median Requester Wait Time (hrs) | Median time tickets sat in a customer-pending state |
| Median Time to Resolve (hrs) | Median hours from ticket creation to resolution |

### Technical highlights

**Universal filter using parameters**

The dashboard surfaces data from two separate fact tables with different date grain columns (`Created At` for volume metrics, `Solved At` for resolution metrics, `First Reply At` for SLA). The universal Year/Month filter works across all eight charts simultaneously by using Tableau parameters rather than standard dimension filters.

Each chart uses a calculated field with the following structure:

```
YEAR([Date Field]) = [Year Filter*]
AND
(
  [Month Filter*] = 0
  OR
  MONTH([Date Field]) = [Month Filter*]
)
```

Setting `[Month Filter*] = 0` corresponds to "All Months," which avoids a `NULL` condition that would break cross-source filtering. This pattern was applied consistently across all eight charts to ensure the parameter selections propagate correctly regardless of which date field each chart references.

**Why this was non-trivial**

Tableau's standard quick filters only work within a single data source. Because this dashboard blends data from two fact tables, a shared dimension filter would either fail silently or require a data blend with relationship overhead. Parameters bypass this limitation entirely — they are workbook-level variables that any calculated field can reference, regardless of source.

### Interactive preview

An interactive HTML mock of this dashboard (illustrative data only) replicates the layout, chart types, color palette, and filter structure of the production dashboard — including a working Year/Month universal filter to demonstrate the parameter behaviour described above.

[View interactive dashboard →](https://melissamagoma.github.io/data_analytics_portfolio/dashboards/spog_dashboard_mock.html)

---

## Support & Product Unified Dashboard

**Audience:** Support Engineering leadership, R&D Executive Leadership, VP-level stakeholders
**Refresh cadence:** Daily
**Data source:** Snowflake (ticketing system and engineering issue tracking fact tables via certified dbt production models)

### What it does

A cross-functional dashboard combining support ticket data with engineering issue and merge request data. Built to surface the relationship between product defect volume and support ticket load — giving both support and engineering leadership a shared view of where the product is generating the most customer friction.

This is the dashboard that required the most data modelling work: joining two separate production fact tables across different schemas, building a canonical product taxonomy to make ticket and engineering data comparable, and maintaining filter consistency across all views.

### Metrics covered

| Metric | Description |
|---|---|
| Solved Ticket Volume | Monthly ticket resolution count |
| AVG CES Score | Average Customer Effort Score (1–7 scale) |
| Median Requester Wait Time (Days) | Median days tickets spent in a customer-pending state, by product group |
| Median Time to Resolution (Days) | Median days from ticket creation to resolution, by product group |
| Open Tagged Issues — Type Mix | Breakdown of open engineering issues by type (bug fix, feature request, unlabelled) |
| Open Tagged Issues — Severity Mix | Breakdown of open engineering issues by severity (S1–S4) |

### Technical highlights

**Two-tab layout with shared filters**

The dashboard is split into two views — an Overview tab for high-level support health, and a Product Breakdown tab for drilling into performance by product group. All filters (Year, Month, Product Stage, Product Group) are shared across both tabs using Tableau parameters, so a filter change on one tab immediately updates the other.

**Cross-source join via canonical product taxonomy**

The core technical challenge was making support ticket data and engineering issue data comparable. Support tickets are categorised by product at the point of triage; engineering issues use a different labelling system. A canonical product taxonomy (~150 categories) was built and maintained in Snowflake as a reference model, used to join and align both sources consistently across all charts.

**Heat map visualisation for product group trends**

The Product Breakdown tab uses a colour-encoded heat map (light blue to amber to red by intensity) to show RWT and MTTR by product group and month simultaneously. This allows leadership to spot outlier product groups at a glance — for example, a single product group with a spike in one month stands out immediately without needing to scroll through a table.

### Interactive preview

An interactive HTML mock of this dashboard (illustrative data only) replicates the tabbed layout, shared filter behaviour, heat map encoding, and chart types of the production dashboard.

[View interactive dashboard →](https://melissamagoma.github.io/data_analytics_portfolio/dashboards/unified_dashboard_mock.html)

---

## Additional dashboards

The following dashboards were also built and maintained as part of the same production analytics function. Included here to show scope of ownership — detail is limited due to confidentiality.

### Support Metrics by Product Category

Breaks down ticket volume, MTTR, and engineering involvement by product category using a canonical taxonomy of ~150 categories. Powers a weekly trend analysis shared with Support leadership. The underlying category mapping was built and maintained separately in Snowflake as a reusable reference model.

### R&D Escalation Dashboard

Built for an R&D Executive Leadership audience. Three views: bugs by status, feature requests, and incidents by severity — all on a rolling 90-day window. Commissioned to give engineering leadership direct visibility into escalated support signals without needing to access the support tooling directly.

### Knowledge Base Analytics Dashboard

Tracks KB article performance across seven datasets. Key calculated metrics include Article Ticket Submission Rate and Article Confirmed Deflection Rate. Applies a minimum page view threshold (≥5) before calculating rates, to avoid distortion from low-traffic articles.

---

## Stack

- **Tableau** (production environment, Site Admin access)
- **Snowflake** (primary data source)
- **dbt** (certified production models joining ticketing and engineering sources)
- **SQL** (custom calculated metrics, date spine logic, cross-source joins)

---

## Abbreviations

| Abbreviation | Definition |
|---|---|
| AVG | Average |
| B2B | Business-to-Business |
| CES | Customer Effort Score — measures how much effort a customer had to put in to get their issue resolved (1–7 scale, lower = less effort) |
| dbt | Data Build Tool — SQL-based transformation framework for data warehouses |
| FRT | First Reply Time — time elapsed between ticket creation and the first agent response |
| KB | Knowledge Base |
| KPI | Key Performance Indicator |
| MR | Merge Request — a code review and integration request in version-controlled engineering workflows |
| MTTR | Median Time to Resolve — median elapsed time from ticket creation to resolution |
| R&D | Research and Development |
| SaaS | Software as a Service |
| SLA | Service Level Agreement — a contractual commitment on response or resolution time |
| SPOG | Single Pane of Glass — a dashboard that consolidates multiple data sources into one unified view |
| VP | Vice President |
