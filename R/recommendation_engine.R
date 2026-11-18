# =============================================================================
# recommendation_engine.R
# CareerLens — ITA04: Statistics with R Programming
# -----------------------------------------------------------------------------
# Evidence-Based Skill Gap & Recommendation Prioritization Engine:
#   1. calculate_recommendation_priorities() - Priority Index (0.70 Role + 0.30 Market),
#                                              empirical co-occurrence, transferability,
#                                              and dynamic narrative explanations.
#   2. export_recommendations_csv()          - Clean tabular data frame for download.
# =============================================================================

source("R/helper_functions.R")
source("R/skill_analysis.R")

# -----------------------------------------------------------------------------
# calculate_recommendation_priorities()
# Evaluates missing skills for candidate in target role, computing:
#   - Target role posting count & demand %
#   - Global market demand %
#   - Priority Index = 0.70 * Role Demand + 0.30 * Market Demand (ranking heuristic)
#   - Category: HIGH (>= 35%), MEDIUM (15% - 35%), ADDITIONAL (< 15%)
#   - Empirical co-occurrence % with candidate's existing skills
#   - Cross-role transferability count
#   - Dynamic evidence narrative
# -----------------------------------------------------------------------------
calculate_recommendation_priorities <- function(df, candidate_skills, target_role) {
  candidate_skills <- if (!is.null(candidate_skills)) trimws(as.character(candidate_skills)) else character(0)
  candidate_skills <- unique(candidate_skills[nzchar(candidate_skills)])

  role_df <- df |> dplyr::filter(as.character(job_title) == target_role)
  n_role  <- nrow(role_df)
  total_jobs <- nrow(df)

  if (n_role == 0) {
    return(list(
      target_role   = target_role,
      n_role        = 0,
      total_jobs    = total_jobs,
      recommendations_tbl = data.frame(),
      high_priority = character(0),
      med_priority  = character(0),
      add_priority  = character(0)
    ))
  }

  # Parse skills for the target role
  role_skills_long <- parse_skills(role_df)
  role_skill_counts <- role_skills_long |>
    dplyr::count(skill, name = "role_postings") |>
    dplyr::mutate(
      role_demand_pct = round((role_postings / n_role) * 100, 1)
    )

  # Parse market-wide skills
  market_skills_long <- parse_skills(df)
  market_skill_counts <- market_skills_long |>
    dplyr::count(skill, name = "market_postings") |>
    dplyr::mutate(
      market_demand_pct = round((market_postings / total_jobs) * 100, 1)
    )

  # Transferability across all roles with >= 50 postings
  role_counts_df <- df |> dplyr::count(job_title, name = "total_postings") |> dplyr::filter(total_postings >= 50)
  transferable_map <- market_skills_long |>
    dplyr::inner_join(role_counts_df, by = "job_title") |>
    dplyr::group_by(skill, job_title) |>
    dplyr::summarise(count = dplyr::n(), total = dplyr::first(total_postings), .groups = "drop") |>
    dplyr::mutate(role_pct = (count / total) * 100) |>
    dplyr::filter(role_pct >= 20, as.character(job_title) != target_role) |>
    dplyr::count(skill, name = "transferable_roles_count")

  # Identify missing skills in role
  missing_skills_df <- role_skill_counts |>
    dplyr::filter(!skill %in% candidate_skills) |>
    dplyr::left_join(market_skill_counts, by = "skill") |>
    dplyr::left_join(transferable_map, by = "skill") |>
    dplyr::mutate(
      market_postings = ifelse(is.na(market_postings), 0L, market_postings),
      market_demand_pct = ifelse(is.na(market_demand_pct), 0, market_demand_pct),
      transferable_roles_count = ifelse(is.na(transferable_roles_count), 0L, transferable_roles_count)
    )

  if (nrow(missing_skills_df) == 0) {
    return(list(
      target_role   = target_role,
      n_role        = n_role,
      total_jobs    = total_jobs,
      recommendations_tbl = data.frame(),
      high_priority = character(0),
      med_priority  = character(0),
      add_priority  = character(0)
    ))
  }

  # Calculate Priority Index: 0.70 * Role Demand + 0.30 * Market Demand
  missing_skills_df <- missing_skills_df |>
    dplyr::mutate(
      priority_index = round(0.70 * role_demand_pct + 0.30 * market_demand_pct, 1),
      priority_category = dplyr::case_when(
        priority_index >= 35.0 ~ "HIGH PRIORITY",
        priority_index >= 15.0 ~ "MEDIUM PRIORITY",
        TRUE                   ~ "ADDITIONAL SKILL"
      )
    ) |>
    dplyr::arrange(dplyr::desc(priority_index))

  # Co-occurrence analysis with candidate's existing skills
  # In role postings containing the missing skill, what % also contain each candidate skill?
  posting_skills_list <- split(role_skills_long$skill, role_skills_long$job_id)

  cooccur_notes <- character(nrow(missing_skills_df))
  top_cooccur   <- character(nrow(missing_skills_df))

  for (i in seq_len(nrow(missing_skills_df))) {
    sk <- missing_skills_df$skill[i]

    # Postings for this role that contain this missing skill
    postings_with_sk <- names(Filter(function(skills) sk %in% skills, posting_skills_list))
    n_postings_sk <- length(postings_with_sk)

    if (n_postings_sk > 0 && length(candidate_skills) > 0) {
      cooccur_pcts <- sapply(candidate_skills, function(c_sk) {
        sum(sapply(postings_with_sk, function(pid) c_sk %in% posting_skills_list[[pid]])) / n_postings_sk * 100
      })
      cooccur_sorted <- sort(cooccur_pcts[cooccur_pcts > 0], decreasing = TRUE)
      if (length(cooccur_sorted) > 0) {
        top_cooccur[i] <- paste(sprintf("%s (%.0f%%)", names(head(cooccur_sorted, 2)), head(cooccur_sorted, 2)), collapse = ", ")
      } else {
        top_cooccur[i] <- "None observed"
      }
    } else {
      top_cooccur[i] <- "N/A"
    }

    # Compose dynamic narrative explanation
    cooccur_phrase <- if (top_cooccur[i] != "N/A" && top_cooccur[i] != "None observed") {
      paste0(" Frequently co-occurs in postings with ", top_cooccur[i], ".")
    } else {
      ""
    }

    trans_phrase <- if (missing_skills_df$transferable_roles_count[i] > 0) {
      sprintf(" Also requested in %d other tech career paths.", missing_skills_df$transferable_roles_count[i])
    } else {
      ""
    }

    cooccur_notes[i] <- sprintf(
      "%s is a %s requirement appearing in %.1f%% (%d/%d) of %s postings and %.1f%% of overall market postings.%s%s",
      sk,
      missing_skills_df$priority_category[i],
      missing_skills_df$role_demand_pct[i],
      missing_skills_df$role_postings[i],
      n_role,
      target_role,
      missing_skills_df$market_demand_pct[i],
      cooccur_phrase,
      trans_phrase
    )
  }

  missing_skills_df$cooccurring_skills     <- top_cooccur
  missing_skills_df$narrative_explanation  <- cooccur_notes

  list(
    target_role          = target_role,
    n_role               = n_role,
    total_jobs           = total_jobs,
    recommendations_tbl  = missing_skills_df,
    high_priority        = missing_skills_df |> dplyr::filter(priority_category == "HIGH PRIORITY") |> dplyr::pull(skill),
    med_priority         = missing_skills_df |> dplyr::filter(priority_category == "MEDIUM PRIORITY") |> dplyr::pull(skill),
    add_priority         = missing_skills_df |> dplyr::filter(priority_category == "ADDITIONAL SKILL") |> dplyr::pull(skill)
  )
}

# -----------------------------------------------------------------------------
# export_recommendations_csv()
# Prepares clean, documented export table for CSV download
# -----------------------------------------------------------------------------
export_recommendations_csv <- function(rec_res) {
  if (is.null(rec_res$recommendations_tbl) || nrow(rec_res$recommendations_tbl) == 0) {
    return(data.frame(Message = "No missing skill recommendations to export for this role."))
  }

  df_out <- rec_res$recommendations_tbl |>
    dplyr::select(
      Skill                   = skill,
      Priority_Category       = priority_category,
      Priority_Index          = priority_index,
      Role_Demand_Pct         = role_demand_pct,
      Role_Postings_Count     = role_postings,
      Market_Demand_Pct       = market_demand_pct,
      Observed_Cooccurrence   = cooccurring_skills,
      Transferable_Other_Roles= transferable_roles_count,
      Evidence_Explanation    = narrative_explanation
    )

  df_out
}
