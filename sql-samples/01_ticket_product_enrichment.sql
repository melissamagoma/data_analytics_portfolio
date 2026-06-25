/*
  Ticket-to-Product Enrichment
  ----------------------------
  Joins support ticket data to product issue metadata, calculates how long
  linked issues have been open, and adds dynamic week-over-week date flags
  for both ticket creation and resolution timestamps.

  This query is the foundation for the Customer Encountered Issues (CEI)
  report, which surfaces product quality signals from support ticket patterns
  and is shared with CTO, CIO, and product leadership for roadmap
  prioritisation. It also drives bug prioritisation by upvote count in
  weekly and monthly executive reporting.

  Schema: anonymised (originally Snowflake production warehouse)
*/

WITH ticket_data AS (
  SELECT
      fct_ticket.ticket_id,
      fct_ticket.has_plan,
      fct_ticket.created_at,
      fct_ticket.solved_at,
      DATE(fct_ticket.solved_at)                                    AS solved_at_date,
      DATE(fct_ticket.created_at)                                   AS created_at_date,
      fct_ticket.is_engineering_involved,
      fct_ticket.requester_wait_time_hours,
      (fct_ticket.time_to_last_resolution_minutes) / 60             AS time_to_last_resolution_hrs,
      fct_ticket.customer_wait_time_ratio_last_resolution,
      dim_ticket.linked_issue_or_mr,
      dim_ticket.linked_issue_url
  FROM analytics.fct_ticket
  LEFT JOIN analytics.dim_ticket
    ON fct_ticket.ticket_id = dim_ticket.ticket_id
  WHERE fct_ticket.has_plan = TRUE
),

issue_data AS (
  -- Pulls product categorisation and issue metadata for tickets linked to product issues
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
      ticket_data.linked_issue_or_mr,
      ticket_data.linked_issue_url,

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

      -- Days open: uses close date if resolved, otherwise counts to today
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
  -- Enriches with date dimension for dynamic WoW week flags on both created and solved timestamps
  SELECT
      joined.*,

      -- Created-at week flags
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

      -- Solved-at week flags
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

-- Example: top bug categories by upvote count for a given month
SELECT DISTINCT
    product_category,
    upvote_count
FROM final
WHERE solved_at >= '2026-05-01'
  AND solved_at < '2026-06-01'
  AND product_category IS NOT NULL
  AND issue_type = 'bug'
  AND upvote_count > 0
ORDER BY upvote_count DESC;
