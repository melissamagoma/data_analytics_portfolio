# Ticket-to-Product Attribution

**Role:** Business Intelligence Analyst, GitLab (SME and collaborator)  
**Stack:** Snowflake, Zendesk, dbt, Anthropic Claude API  
**Collaborators:** Analytics Engineering  
**Outcome:** First systematic framework connecting 200K+ support tickets to product development priorities at GitLab

---

## The problem

GitLab's support function generates thousands of tickets a week across a product surface spanning CI/CD, Security, AI, Infrastructure, and more. The data existed, but there was no reliable way to connect support volume to specific product areas at scale, especially given that raw ticket subject and description fields couldn't be directly ingested into downstream tools due to security and compliance constraints.

Without reliable attribution, product teams were making prioritization decisions without a clear picture of where customers were actually struggling.

---

## My contribution

I was brought in as the Zendesk data SME when the Analytics Engineering team scoped this initiative. My contributions were:

- Surfaced existing product categorization data already available in our data warehouse, saving the team from rebuilding attribution logic from scratch
- Advised on the Zendesk data structure, ticket tagging conventions, and the limitations of existing classification approaches
- Connected the team to the right internal SMEs for keyword-to-product-area validation
- Provided context on the Meltano-to-Fivetran migration and how it affected the underlying data sources
- Linked the initiative to a related legal and security review covering Zendesk ticket data ingestion into Snowflake

The pipeline itself was built by the Analytics Engineering team, with the AI summarization and categorization layer processing tickets through an LLM before ingestion into the unified GTM feedback model.

---

## How it works

Tickets are processed through an LLM to extract keywords, classify product area, and generate summaries without exposing raw subject or description fields. The output maps each ticket to one of five strategic product areas: Core DevOps, AI, Monetization, Platforms & Infrastructure, and Security. Processed data is enriched with CRM account data, ARR, and sales segment before being unioned with other customer feedback sources.

---

## Outcome

- 200K+ tickets across three years made accessible for product-level analysis without exposing sensitive content
- Product teams gained direct visibility into support clustering by product area
- Attribution framework feeds into GitLab's unified GTM customer feedback program alongside CSAT, CS Plans, and escalation data
- Established a reusable data structure for ongoing Zendesk-to-product-feedback integration
