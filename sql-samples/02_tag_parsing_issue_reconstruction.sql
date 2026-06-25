/*
  Tag Parsing and Issue/MR URL Reconstruction
  --------------------------------------------
  Zendesk tickets carry structured tags encoding linked GitLab issues and MRs
  (e.g. "gitlab-org_gitlab_issue_12345"). This query parses those tags,
  reconstructs the full GitLab URL, and enriches each tag with issue metadata
  including product group, severity, priority, and ticket count.

  The join between tag-derived issue numbers and the issue dimension uses
  ROW_NUMBER() to deduplicate when multiple issues share the same number,
  keeping the most recently updated record.

  Use case: surfaces which GitLab issues and MRs are generating the most
  support ticket volume in a given period, used in weekly reporting and
  escalation prioritisation.

  Schema: anonymised (originally Snowflake production warehouse)
*/

WITH ticket_tags_unnested AS (
  -- Split comma-separated tag strings so each tag gets its own row
  -- Normalises "_issues_" to "_issue_" to deduplicate tag variants
  SELECT DISTINCT
      dim_ticket.ticket_id,
      REGEXP_REPLACE(TRIM(tag.value), '_issues_', '_issue_') AS tag,
      fct_ticket.created_at,
      fct_ticket.solved_at
  FROM analytics.dim_ticket
  LEFT JOIN analytics.fct_ticket
    ON dim_ticket.ticket_id = fct_ticket.ticket_id,
  LATERAL SPLIT_TO_TABLE(dim_ticket.ticket_tags, ',') AS tag
  WHERE fct_ticket.solved_at BETWEEN '2025-12-01' AND '2025-12-31'
),

ticket_tags_aggregated AS (
  -- Count tickets per tag and collect ticket IDs
  SELECT
      tag,
      COUNT(DISTINCT ticket_id)                                              AS ticket_count,
      LISTAGG(DISTINCT ticket_id, ', ') WITHIN GROUP (ORDER BY ticket_id)   AS ticket_ids
  FROM ticket_tags_unnested
  WHERE (tag ILIKE '%_mergerequest_%' OR tag ILIKE '%_issue_%')
    AND (tag ILIKE '%namespace-a%' OR tag ILIKE '%namespace-b%')
  GROUP BY tag
),

tag_parsed AS (
  -- Extract issue/MR number from the tag and derive the URL path
  SELECT
      tag,
      ticket_count,
      ticket_ids,
      REGEXP_SUBSTR(tag, '[0-9]+$')                        AS issue_mr_number,
      CASE
          WHEN tag ILIKE '%_issue_%'        THEN 'issue'
          WHEN tag ILIKE '%_mergerequest_%' THEN 'merge_request'
      END                                                  AS link_type,
      REPLACE(
          REGEXP_REPLACE(tag, '_(issue|mergerequest)_[0-9]+$', ''),
          '_', '/'
      )                                                    AS url_path
  FROM ticket_tags_aggregated
),

tag_with_urls AS (
  -- Reconstruct full URLs from parsed components
  SELECT
      tag,
      ticket_count,
      ticket_ids,
      link_type,
      issue_mr_number,
      CASE
          WHEN link_type = 'merge_request'
              THEN 'https://example.com/' || url_path || '/-/merge_requests/' || issue_mr_number
          ELSE    'https://example.com/' || url_path || '/-/issues/'          || issue_mr_number
      END AS reconstructed_url
  FROM tag_parsed
  WHERE issue_mr_number IS NOT NULL
),

issue_data AS (
  -- Pull issue metadata and product categorisation
  SELECT
      dim_issue.issue_id,
      dim_issue.issue_title,
      dim_issue.issue_url,
      dim_issue.issue_state,
      dim_issue.issue_type,
      dim_issue.severity,
      dim_issue.priority,
      dim_issue.created_at        AS issue_created_at,
      dim_issue.closed_at         AS issue_closed_at,
      dim_issue.updated_at,
      user_request.product_group,
      user_request.product_stage,
      user_request.product_category,
      -- Extract trailing issue number from URL for matching
      REGEXP_SUBSTR(dim_issue.issue_url, '[0-9]+$') AS issue_number_from_url
  FROM analytics.dim_issue
  LEFT JOIN analytics.mart_user_request AS user_request
    ON dim_issue.issue_id = user_request.issue_id
  WHERE dim_issue.issue_url IS NOT NULL
),

final AS (
  -- Join tags to issue metadata on extracted issue number
  -- ROW_NUMBER deduplicates when multiple issues share the same number,
  -- keeping the most recently updated record
  SELECT
      tag_with_urls.tag,
      tag_with_urls.ticket_count,
      tag_with_urls.ticket_ids,
      tag_with_urls.link_type,
      tag_with_urls.issue_mr_number,
      tag_with_urls.reconstructed_url,
      issue_data.issue_id,
      issue_data.issue_title,
      issue_data.issue_state,
      issue_data.issue_type,
      issue_data.severity,
      issue_data.priority,
      issue_data.product_group,
      issue_data.product_stage,
      issue_data.product_category,
      issue_data.issue_created_at,
      issue_data.issue_closed_at,
      ROW_NUMBER() OVER (
          PARTITION BY tag_with_urls.tag
          ORDER BY issue_data.updated_at DESC NULLS LAST
      ) AS rn
  FROM tag_with_urls
  LEFT JOIN issue_data
    ON tag_with_urls.issue_mr_number = issue_data.issue_number_from_url
)

SELECT *
FROM final
WHERE rn = 1
ORDER BY ticket_count DESC;
