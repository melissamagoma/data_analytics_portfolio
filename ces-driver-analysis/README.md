# CES Driver Analysis: Requester Wait Time as the Primary Driver of Customer Effort Score

**Role:** Business Intelligence Analyst, GitLab (sole analyst)  
**Stack:** Zendesk Explore, Snowflake, Tableau, SQL  
**Outcome:** Confirmed RWT as the primary driver of CES, changing how leadership interpreted support performance and allocated resources

---

## The problem

Customer Effort Score was tracked weekly but nobody had formally tested what actually drove it. The working assumption was that MTTR (time to resolution) was the key lever. When CES dropped in late 2025, I opened a structured investigation to find out what was actually causing it.

---

## The investigation

I built a Zendesk Explore pivot analysis covering four consecutive weeks, tracking CES score alongside Requester Wait Time and Engineering Involvement Rate simultaneously.

The pattern was clear. When wait time dropped significantly week over week, CES rose to target. In the weeks that followed, CES held steady even as wait times crept back up, pointing to a threshold effect: customers tolerate waits up to a point, but once wait time exceeds that range, CES degrades.

Engineering Involvement Rate fluctuations had minimal impact on CES across the same period. Customers were more sensitive to how long they waited than to whether their ticket required engineering escalation.

I also reviewed CSAT comments for the same period to triangulate the quantitative finding with qualitative signal. The comments confirmed the pattern: frustration was concentrated in tickets with long open durations, not tickets with complex resolutions.

---

## The finding

Requester Wait Time is the primary driver of CES. MTTR is not.

This matters because they measure different things. RWT measures how long a customer is actively waiting between responses. MTTR measures total time from creation to resolution, including time spent waiting on the customer. Optimizing for MTTR without attention to RWT can mask queue problems that directly affect customer experience.

The finding also identified an approximate wait time threshold where CES stabilizes at target. Beyond that range, satisfaction degrades predictably.

---

## How it changed things

Prior to this analysis, leadership interpreted CES primarily through the lens of resolution efficiency. The finding reframed the conversation: the question became not "how fast are we closing tickets" but "how long are customers sitting in the queue."

RWT was subsequently added as a formal performance indicator alongside CES in executive reporting, visualized together to make the relationship explicit. The finding was documented in the Support Data Dictionary and referenced in the handbook Performance Indicators rebuild as the basis for elevating RWT to a tracked metric.

---

## What made this one interesting

The finding ran counter to the intuitive assumption. Most people would guess that resolving tickets faster improves satisfaction. The data showed that customers care more about feeling attended to during the process than about how quickly the ticket closes. That's a meaningfully different operational problem.
