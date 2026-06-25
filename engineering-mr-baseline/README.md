# Engineering MR Baseline: FY26 Merge Request Analysis

**Role:** Business Intelligence Analyst, GitLab (analytics contributor)  
**Stack:** Snowflake, SQL, Google Sheets  
**Context:** Baseline analytics work for a company AI modernization initiative focused on agentic support workflows  
**Outcome:** First structured baseline of GitLab engineering MR activity by contributor type, MR type, product group, and stage

---

## The problem

GitLab was scoping an initiative to turn Support signals into upstream merge requests at scale, using agentic workflows to propose, draft, and validate MRs from customer tickets, escalations, and support threads. The vision: make Support a proactive contributor to the codebase rather than treating tickets as an endpoint.

Before that could happen, there was a foundational question nobody had answered: what does current MR activity actually look like? How much of the work is bug fixes versus feature development versus maintenance? Which product groups are generating the most volume? How do support-originated contributions compare to the broader engineering baseline?

The initiative required a quantified baseline before the team could set targets, design the agent workflow, or measure uplift.

---

## The approach

I pulled all merge requests created during a full fiscal year from Snowflake and segmented them across four contributor pools:

- **All engineering MRs** — the full picture of engineering output for the year
- **Support team contributions** — MRs originating from the support team
- **Customer-related MRs** — MRs flagged as directly customer-related
- **Community contributions** — MRs from community contributors

Each pool was broken down by MR type (bug, feature, maintenance, undefined), product group, section, and stage, producing a cross-referenced view of where work was happening and what kind it was.

---

## What the data showed

Across the full engineering dataset, maintenance work dominated volume — expected at GitLab's scale. Feature MRs were concentrated in a relatively small number of high-activity product groups, while bug MRs were more evenly distributed across the product surface.

The support team and community contribution pools showed meaningfully different patterns from the overall engineering baseline, with higher proportions of bug fixes relative to feature work. This is consistent with contributors responding to customer-reported issues rather than roadmap-driven development, and helped frame where the agentic workflow could have the most targeted impact.

Customer-related MRs were similarly bug-heavy, with a handful of product groups accounting for a disproportionate share of volume.

---

## Why it mattered

This baseline gave the initiative something concrete to build on. Without it, targets for support-originated MR rate uplift, backlog conversion, and engineering escalation reduction had no anchor. The data defined the starting point that subsequent phases would measure against.

It also made the distribution of contribution visible for the first time — which product groups, which MR types, which contributor pools — in a way that could directly inform where the agent workflow should focus first.

---

## What I'd do differently

The undefined label category was significant in volume across all pools, which limits the precision of type-level analysis. Earlier alignment with engineering on labeling standards would have made the baseline cleaner and more directly actionable from the start.
