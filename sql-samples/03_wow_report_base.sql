/*
  WoW Report Base: Engineering-Involved Tickets with Product Attribution
  ----------------------------------------------------------------------
  Pulls engineering-involved tickets for a given week, enriched with product
  group and category data, and filtered to remove duplicates and follow-up
  tickets using tag-based exclusion logic.

  Output feeds the weekly Support Bulletin and the Top 10 MTTR product
  category analysis in the Week-over-Week (WoW) report, shared with VP
  and E-Group audiences.

  Key design decisions:
  - ARRAY_CONTAINS used on the pre-split tags array to exclude duplicate and
    follow-up tickets cleanly without re-parsing the tag string
  - Tickets where both product_group and product_category are NULL are excluded
    since they cannot be attributed to a product area
  - Time to resolution converted from minutes to hours inline
  - Dynamic WoW date flags added via dim_date joins for both created and solved
    timestamps, enabling consistent week-over-week comparisons

  Schema: anonymised (originally Snowflake production warehouse)
*/

WITH ticket_data AS (
  SELECT
      fct_ticket.ticket_id,
      fct_ticket.has_plan,
      fct_ticket.created_at,
      fct_ticket.solved_at,
      DATE(fct_ticket.solved_at)                              AS solved_at_date,
      DATE(fct_ticket.created_at)                             AS created_at_date,
      fct_ticket.is_engineering_involved,
      fct_ticket.requester_wait_time_hours,
      (fct_ticket.time_to_last_resolution_minutes) / 60       AS time_to_last_resolution_hrs,
      fct_ticket.customer_wait_time_ratio_last_resolution,
      fct_ticket.is_follow_up,
      dim_ticket.linked_issue_or_mr,
      dim_ticket.linked_issue_url,
      dim_ticket.ticket_tags,
      dim_ticket.ticket_tags_array
  FROM analytics.fct_ticket
  LEFT JOIN analytics.dim_ticket
    ON fct_ticket.ticket_id = dim_ticket.ticket_id
  WHERE fct_ticket.has_plan = TRUE
),

issue_data AS (
  SELECT
      user_request.ticket_id,
      user_request.issue_id,
      user_request.issue_title,
      user_request.issue_url,
      user_request.issue_status,
      user_request.issue_type,
      user_request.milestone_title,
      user_request.product_group,
      user_request.product_stage,
      user_request.product_category,
      user_request.upvote_count,
      dim_issue.severity,
      dim_issue.priority,
      user_request.issue_created_at,
      user_request.issue_closed_at
  FROM analytics.mart_user_request AS user_request
  LEFT JOIN analytics.dim_issue
    ON user_request.issue_id = dim_issue.issue_id
),

joined AS (
  SELECT
      ticket_data.ticket_id,
      ticket_data.has_plan,
      ticket_data.created_at,
      ticket_data.solved_at,
      ticket_data.solved_at_date,
      ticket_data.created_at_date,
      ticket_data.is_engineering_involved,
      ticket_data.requester_wait_time_hours,
      ticket_data.time_to_last_resolution_hrs,
      ticket_data.customer_wait_time_ratio_last_resolution,
      ticket_data.is_follow_up,
      ticket_data.linked_issue_or_mr,
      ticket_data.linked_issue_url,
      ticket_data.ticket_tags,
      ticket_data.ticket_tags_array,
      issue_data.issue_id,
      issue_data.issue_title,
      issue_data.issue_url,
      issue_data.issue_status,
      issue_data.issue_type,
      issue_data.milestone_title,
      issue_data.product_group,
      issue_data.product_stage,
      issue_data.product_category,
      issue_data.upvote_count,
      issue_data.severity,
      issue_data.priority,
      issue_data.issue_created_at,
      issue_data.issue_closed_at,
      CASE
          WHEN issue_data.issue_closed_at IS NULL
              THEN DATEDIFF('day', issue_data.issue_created_at, CURRENT_DATE())
          ELSE DATEDIFF('day', issue_data.issue_created_at, issue_data.issue_closed_at)
      END AS days_open
  FROM ticket_data
  LEFT JOIN issue_data
    ON ticket_data.ticket_id = issue_data.ticket_id
),

final AS (
  SELECT
      joined.*,
      created_dim.first_day_of_week                                              AS created_week_start,
      DATEADD('day', -1, created_dim.first_day_of_week)                         AS created_week_start_sunday,
      IFF(DATEADD('day', -1, created_dim.first_day_of_week)
          = DATEADD('day', -1, created_dim.current_first_day_of_week),
          TRUE, FALSE)                                                            AS is_created_this_week,
      IFF(DATEADD('day', -1, created_dim.first_day_of_week)
          = DATEADD('day', -7, DATEADD('day', -1, created_dim.current_first_day_of_week)),
          TRUE, FALSE)                                                            AS is_created_last_week,
      IFF(DATEADD('day', -1, created_dim.first_day_of_week)
          = DATEADD('day', -14, DATEADD('day', -1, created_dim.current_first_day_of_week)),
          TRUE, FALSE)                                                            AS is_created_week_before_last,
      solved_dim.first_day_of_week                                               AS solved_week_start,
      DATEADD('day', -1, solved_dim.first_day_of_week)                          AS solved_week_start_sunday,
      IFF(DATEADD('day', -1, solved_dim.first_day_of_week)
          = DATEADD('day', -1, solved_dim.current_first_day_of_week),
          TRUE, FALSE)                                                            AS is_solved_this_week,
      IFF(DATEADD('day', -1, solved_dim.first_day_of_week)
          = DATEADD('day', -7, DATEADD('day', -1, solved_dim.current_first_day_of_week)),
          TRUE, FALSE)                                                            AS is_solved_last_week,
      IFF(DATEADD('day', -1, solved_dim.first_day_of_week)
          = DATEADD('day', -14, DATEADD('day', -1, solved_dim.current_first_day_of_week)),
          TRUE, FALSE)                                                            AS is_solved_week_before_last
  FROM joined
  LEFT JOIN analytics.dim_date AS created_dim
    ON joined.created_at_date = created_dim.date_actual
  LEFT JOIN analytics.dim_date AS solved_dim
    ON joined.solved_at_date = solved_dim.date_actual
)

-- Engineering-involved tickets for the reporting week, deduplicated via tag exclusions
SELECT DISTINCT
    ticket_id,
    requester_wait_time_hours,
    time_to_last_resolution_hrs,
    product_group,
    product_category
FROM final
WHERE solved_at >= '2026-05-10'
  AND solved_at < '2026-05-17'
  AND ticket_id IS NOT NULL
  AND NOT (product_group IS NULL AND product_category IS NULL)
  AND is_engineering_involved = TRUE
  AND is_follow_up = FALSE
  AND NOT ARRAY_CONTAINS('closed_by_merge'::VARIANT, ticket_tags_array)   -- excludes merged duplicates
  AND NOT ARRAY_CONTAINS('followup_ticket'::VARIANT, ticket_tags_array);  -- excludes follow-up tickets
