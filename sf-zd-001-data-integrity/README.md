# SF-ZD-001: Cross-Platform Data Integrity Investigation

**Role:** Business Intelligence Analyst, GitLab (sole investigator)  
**Stack:** Snowflake, Zendesk Explore, Fivetran, Tableau, SQL  
**Outcome:** Root cause identified, documented as a permanent governance standard across all Zendesk-sourced Snowflake reporting

---

## The problem

GitLab's support metrics were showing 100% consistency between Zendesk Explore and Snowflake at the individual ticket level, but only ~91% consistency at the aggregate level across key metrics including FRT, NRT, CES, RWT, and MTTR. A persistent ~9% gap that nobody had explained.

As reporting scaled into Tableau and Snowflake, this discrepancy became harder to ignore. Stakeholders were seeing different numbers depending on where they looked, and there was no documented reason why.

---

## The investigation

I ran a structured five-step analysis, starting with the most common culprits and narrowing down systematically:

1. Tested timezone conversion on ticket creation timestamps: no change
2. Tested timezone conversion on resolution timestamps: no change
3. Applied boolean filters to match Zendesk Explore's default query behavior: gap narrowed but persisted
4. Isolated to complete months and pulled ticket IDs for direct comparison, identifying a consistent gap of ~100 tickets per quarter present in Snowflake but absent from Zendesk Explore
5. Inspected the discrepant tickets: confirmed permanent deletion as the root cause

---

## Root cause

Permanently deleted tickets.

Zendesk has two deletion pathways: manual permanent deletion by an agent, and automatic permanent deletion after a ticket has sat in the deleted view for 30 days. Both result in all user-submitted content being scrubbed from Zendesk's systems and becoming unreportable in Explore.

However, Zendesk's Incremental Ticket Export API, which Fivetran uses to sync data into Snowflake, retains scrubbed ticket records. The ticket still exists in the API response, Fivetran syncs it, and it lands in the data warehouse with no flag to distinguish it from an active ticket. This is documented Zendesk API behavior, not a pipeline or modeling gap.

The effect surfaces across every metric that aggregates ticket populations:

- **Incoming volume:** permanently deleted tickets retain a valid creation timestamp in Snowflake, inflating volume counts relative to Explore
- **Resolved volume:** Zendesk Explore's solved metric requires current ticket status to be Solved or Closed, so solved-then-deleted tickets drop out of Explore entirely while remaining in Snowflake
- **FRT achievement:** deleted tickets stay in the Snowflake denominator but are excluded from Explore, mechanically shifting the rate
- **Median RWT and MTTR:** extra tickets land unpredictably across the distribution, shifting the median in ways that cannot be anticipated or corrected

---

## Why it cannot be fixed

Three fixes were evaluated and ruled out:

**Timezone correction:** ruled out in steps 1 and 2, no impact on the gap.

**IS_DELETED flag:** technically infeasible. Permanently deleted tickets leave no trace in Zendesk, so Fivetran has nothing to sync a deletion status from unless it happened to capture a soft-delete record in the window between deletion and purge, which cannot be relied on systematically.

**Form-based filter:** ruled out after inspecting the discrepant tickets. Deletions spanned both internal and customer-facing form types, meaning a form filter would drop legitimate customer tickets from reporting while only capturing a fraction of the deleted ones.

---

## Outcome

- Root cause documented as reference ID SF-ZD-001 in the Support Data Dictionary as a permanent known limitation
- README caveat added to the Support Metrics Tableau dashboard noting that the data source may include permanently deleted tickets with no filter mechanism available
- Adopted as an org-wide governance reference across all Zendesk-sourced Snowflake table definitions
- Cross-platform consistency now formally established at ~91%, with the gap fully explained and documented

---

## What made this one interesting

The ticket-level data was perfect. Every individual ticket that existed in both systems matched exactly. The discrepancy only appeared in aggregates, which made the root cause harder to identify because it wasn't a data quality problem in the traditional sense. It was a population mismatch driven by a documented platform behavior that nobody had traced before.
