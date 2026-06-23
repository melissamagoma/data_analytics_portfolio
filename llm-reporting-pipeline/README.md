# LLM Reporting Pipeline

**Role:** Business Intelligence Analyst, GitLab  
**Stack:** Anthropic Claude API, MCP (Slack, Google Drive, GitLab, Zendesk), Python, Snowflake, SQL  
**Outcome:** 75-90% reduction in weekly executive reporting turnaround

---

## The problem

GitLab's weekly support reporting cycle was fully manual. Every week, I pulled data from multiple sources, mapped incidents and tickets to product categories across ~150 options, drafted narrative summaries for VP and E-Group audiences, and posted outputs across Slack, Google Drive, and GitLab. The process was accurate but slow, and the repetition left little room for the deeper analytical work that actually moves things forward.

The challenge wasn't just speed. The outputs fed executive decision-making, so accuracy wasn't negotiable. Any automation had to meet the same quality bar as the manual process, or it wasn't worth building.

---

## The approach

I built an agentic reporting pipeline on the Anthropic Claude API, structured around a library of reusable prompt skills: specification files that encode report templates, data interpretation rules, output formatting logic, and executive narrative patterns.

The key design decision was to treat quality as a first-class requirement, not an afterthought. Rather than letting the model infer product category mappings from context, I built strict validation logic that maps tickets against a canonical CSV and hard-stops on anything outside it. That decision came directly from experience: early iterations would confidently produce category names that didn't exist, which is worse than a gap in the data.

MCP server integrations handle the distribution layer, posting outputs to Slack, Google Drive, and GitLab without manual intervention. The pipeline covers the full weekly cycle: data ingestion, category mapping, narrative generation, QA, and publishing.

---

## How it evolved

The first version automated the output. Each subsequent iteration tightened the guardrails. I added programmatic QA checks, stricter category mapping validation, and outlier detection logic for anomalous metrics. The skill library grew to cover the weekly WoW report, monthly business reviews, quarterly bulletins, and incident analysis.

The shift in thinking was from "automate the task" to "automate with enough structure that the output is trustworthy enough to go directly to an E-Group audience."

---

## Outcome

- Weekly executive reporting turnaround reduced by 75-90%
- Zero manual distribution steps across Slack, Google Drive, and GitLab
- Reusable skill library now covers the full reporting suite: WoW reports, monthly business reviews, quarterly bulletins, and incident analysis
- Freed up analytical capacity for higher-signal investigations, including the SF-ZD-001 data integrity investigation and the CES driver analysis

---

## What I'd do differently

I'd invest earlier in the QA layer. The category mapping validation was added reactively after early errors made it into drafts. Building strict validation in from the start would have saved iteration cycles and built trust in the outputs faster.
