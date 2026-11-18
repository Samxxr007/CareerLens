# =============================================================================
# career_fit.R
# CareerLens — ITA04: Statistics with R Programming
# -----------------------------------------------------------------------------
# Core Candidate Matching & Career Fit Engine:
#   1. normalize_candidate_skills()     - Case normalization & alias mapping
#   2. build_job_skill_matrix()         - Distinct (job_id, skill) long format
#   3. calculate_role_skill_demand()    - Complete role vocabulary demand %
#   4. calculate_posting_skill_overlap()- Posting-level overlap percentage vector
#   5. calculate_candidate_role_match() - Dual metrics (Coverage & 80% Overlap) +
#                                         compatibility context
#   6. rank_career_matches()            - Ranks all eligible roles for candidate
#   7. compare_career_paths()           - Side-by-side comparative analysis
#   8. simulate_profile_change()        - Before-and-after delta recalculations
# =============================================================================

source("R/helper_functions.R")
source("R/skill_analysis.R")

# -----------------------------------------------------------------------------
# 1. normalize_candidate_skills()
# Normalizes user skill input with whitespace trimming and canonical alias mapping
# -----------------------------------------------------------------------------
normalize_candidate_skills <- function(skills) {
  if (is.null(skills) || length(skills) == 0) return(character(0))
  skills <- trimws(as.character(skills))
  skills <- skills[nzchar(skills)]
  if (length(skills) == 0) return(character(0))

  # Common alias canonicalization table
  alias_map <- c(
    "py"          = "Python",
    "python3"     = "Python",
    "postgres"    = "PostgreSQL",
    "k8s"         = "Kubernetes",
    "aws"         = "AWS",
    "gcp"         = "GCP",
    "powerbi"     = "Power BI",
    "power bi"    = "Power BI",
    "js"          = "JavaScript",
    "ts"          = "TypeScript",
    "sklearn"     = "scikit-learn",
    "scikit learn"= "scikit-learn",
    "node"        = "Node.js",
    "nodejs"      = "Node.js",
    "c plus plus" = "C++",
    "c sharp"     = "C#",
    "dot net"     = ".NET",
    "dotnet"      = ".NET"
  )

  normalized <- sapply(skills, function(s) {
    s_lower <- tolower(s)
    if (s_lower %in% names(alias_map)) {
      alias_map[[s_lower]]
    } else {
      s
    }
  }, USE.NAMES = FALSE)

  unique(normalized)
}

# Alias for backwards compatibility
standardize_skills <- normalize_candidate_skills

# -----------------------------------------------------------------------------
# 2. build_job_skill_matrix()
# Returns distinct (job_id, skill) long data frame
# -----------------------------------------------------------------------------
build_job_skill_matrix <- function(df) {
  parse_skills(df)
}

# -----------------------------------------------------------------------------
# 3. calculate_role_skill_demand()
# Calculates frequency and demand % across ALL recognized skills for the target role
# (No arbitrary top-30 cutoff)
# -----------------------------------------------------------------------------
calculate_role_skill_demand <- function(df, target_role) {
  role_df <- df |> dplyr::filter(as.character(job_title) == target_role)
  n_role  <- nrow(role_df)
  if (n_role == 0) return(data.frame())

  role_long <- parse_skills(role_df)

  role_long |>
    dplyr::count(skill, skill_category, name = "postings_count") |>
    dplyr::mutate(
      demand_pct = round((postings_count / n_role) * 100, 1),
      rank       = rank(-postings_count, ties.method = "min")
    ) |>
    dplyr::arrange(rank)
}

# -----------------------------------------------------------------------------
# 4. calculate_posting_skill_overlap()
# Evaluates each posting in target role:
# (Count of candidate skills matching posting) / (Distinct recognized skills in posting) * 100
# -----------------------------------------------------------------------------
calculate_posting_skill_overlap <- function(df, candidate_skills, target_role) {
  candidate_skills <- normalize_candidate_skills(candidate_skills)
  role_df <- df |> dplyr::filter(as.character(job_title) == target_role)
  n_postings <- nrow(role_df)
  if (n_postings == 0) return(numeric(0))

  posting_skill_lists <- lapply(strsplit(role_df$skills, ";"), function(s) {
    normalize_candidate_skills(s)
  })

  overlaps <- sapply(posting_skill_lists, function(reqs) {
    if (length(reqs) == 0) return(0)
    round((sum(reqs %in% candidate_skills) / length(reqs)) * 100, 1)
  })

  overlaps
}

# -----------------------------------------------------------------------------
# 5. calculate_candidate_role_match()
# Central analytical function computing:
#   - Distinct Skill Coverage (%)
#   - Demand-Weighted Skill Coverage (%)
#   - Posting Overlap: % >= 50%, % >= 80%, % = 100%, and Median
#   - Experience & Education compatibility
#   - Role salary distribution
# -----------------------------------------------------------------------------
calculate_candidate_role_match <- function(df, candidate_skills, target_role,
                                          candidate_exp = NULL, candidate_edu = NULL,
                                          candidate_loc = NULL) {
  candidate_skills <- normalize_candidate_skills(candidate_skills)
  role_df <- df |> dplyr::filter(as.character(job_title) == target_role)
  n_postings <- nrow(role_df)

  if (n_postings == 0) {
    return(list(
      target_role       = target_role,
      n_postings        = 0,
      skill_coverage    = 0,
      weighted_coverage = 0,
      overlap_ge_50     = 0,
      overlap_ge_80     = 0,
      overlap_eq_100    = 0,
      median_overlap    = 0,
      posting_overlap   = 0,
      matched_skills    = character(0),
      missing_skills    = character(0),
      skills_breakdown  = data.frame(),
      missing_skills_tbl= data.frame(),
      salary_context    = list(),
      exp_compatibility = list(),
      edu_compatibility = list(),
      warning_msg       = paste0("No postings found for '", target_role, "'.")
    ))
  }

  # All recognized skills for this role
  role_skill_tbl <- calculate_role_skill_demand(df, target_role)
  role_distinct_skills <- role_skill_tbl$skill
  n_distinct_role_skills <- length(role_distinct_skills)

  # Distinct skill coverage
  matched_distinct <- intersect(candidate_skills, role_distinct_skills)
  missing_distinct <- setdiff(role_distinct_skills, candidate_skills)

  skill_coverage <- if (n_distinct_role_skills > 0) {
    round((length(matched_distinct) / n_distinct_role_skills) * 100, 1)
  } else {
    0
  }

  # Demand-weighted skill coverage:
  # (Sum of demand weights for matched skills) / (Sum of demand weights for all role skills) * 100
  total_demand_weight <- sum(role_skill_tbl$demand_pct)
  matched_demand_weight <- sum(role_skill_tbl$demand_pct[role_skill_tbl$skill %in% matched_distinct])

  weighted_coverage <- if (total_demand_weight > 0) {
    round((matched_demand_weight / total_demand_weight) * 100, 1)
  } else {
    0
  }

  # Posting-level skill overlaps
  overlap_vec <- calculate_posting_skill_overlap(df, candidate_skills, target_role)
  overlap_ge_50  <- round(mean(overlap_vec >= 50.0) * 100, 1)
  overlap_ge_80  <- round(mean(overlap_vec >= 80.0) * 100, 1)
  overlap_eq_100 <- round(mean(overlap_vec >= 100.0) * 100, 1)
  median_overlap <- round(median(overlap_vec), 1)

  # Posting-level match (using the 80% threshold)
  posting_overlap <- overlap_ge_80

  # Breakdown table
  skills_breakdown <- role_skill_tbl |>
    dplyr::mutate(
      status = ifelse(skill %in% candidate_skills, "Matched", "Missing")
    )

  missing_skills_tbl <- skills_breakdown |>
    dplyr::filter(status == "Missing") |>
    dplyr::arrange(dplyr::desc(demand_pct))

  # Salary distribution for target role (non-missing values)
  sal_vals <- role_df$salary_inr[!is.na(role_df$salary_inr)]
  salary_context <- if (length(sal_vals) > 0) {
    list(
      n      = length(sal_vals),
      mean   = as.numeric(mean(sal_vals)),
      median = as.numeric(median(sal_vals)),
      q1     = as.numeric(quantile(sal_vals, 0.25)),
      q3     = as.numeric(quantile(sal_vals, 0.75)),
      p10    = as.numeric(quantile(sal_vals, 0.10)),
      p90    = as.numeric(quantile(sal_vals, 0.90)),
      iqr    = as.numeric(quantile(sal_vals, 0.75) - quantile(sal_vals, 0.25))
    )
  } else {
    list()
  }

  # Experience compatibility
  exp_compat <- if (!is.null(candidate_exp)) {
    exp_num <- as.numeric(candidate_exp)
    pct_qual <- round(mean(role_df$experience_years <= exp_num, na.rm = TRUE) * 100, 1)
    mean_exp <- round(mean(role_df$experience_years, na.rm = TRUE), 1)
    list(candidate_exp = exp_num, pct_qualified = pct_qual, role_mean_exp = mean_exp)
  } else {
    list(candidate_exp = NA, pct_qualified = NA, role_mean_exp = round(mean(role_df$experience_years, na.rm = TRUE), 1))
  }

  # Warning for small sample size (< 50 postings)
  warning_msg <- if (n_postings < 50) {
    sprintf("Sample size notice: Role '%s' has only %d postings in dataset (sample size < 50). Statistical estimates carry higher uncertainty.", target_role, n_postings)
  } else {
    NULL
  }

  list(
    target_role            = target_role,
    n_postings             = n_postings,
    skill_coverage         = skill_coverage,
    weighted_coverage      = weighted_coverage,
    overlap_ge_50          = overlap_ge_50,
    overlap_ge_80          = overlap_ge_80,
    overlap_eq_100         = overlap_eq_100,
    median_overlap         = median_overlap,
    posting_overlap        = posting_overlap,
    matched_skills         = matched_distinct,
    missing_skills         = missing_distinct,
    skills_breakdown       = skills_breakdown,
    missing_skills_tbl     = missing_skills_tbl,
    salary_context         = salary_context,
    exp_compatibility      = exp_compat,
    warning_msg            = warning_msg
  )
}

# Alias for backwards compatibility
calculate_career_fit <- calculate_candidate_role_match

# -----------------------------------------------------------------------------
# 6. rank_career_matches()
# Shortlist of all roles in dataset with >= min_postings
# Ranked primarily by Posting Overlap (>=80%), secondarily by Weighted Coverage
# -----------------------------------------------------------------------------
rank_career_matches <- function(df, candidate_skills, min_postings = 50) {
  candidate_skills <- normalize_candidate_skills(candidate_skills)

  roles_summary <- df |>
    dplyr::count(job_title, name = "posting_count") |>
    dplyr::filter(posting_count >= min_postings) |>
    dplyr::mutate(role_str = as.character(job_title))

  if (nrow(roles_summary) == 0) {
    return(data.frame())
  }

  match_list <- lapply(roles_summary$role_str, function(r) {
    m <- calculate_candidate_role_match(df, candidate_skills, r)
    med_sal <- if (length(m$salary_context) > 0) round(m$salary_context$median) else NA_real_

    data.frame(
      Job_Role           = r,
      Posting_Count      = m$n_postings,
      Posting_Overlap_80 = m$overlap_ge_80,
      Weighted_Coverage  = m$weighted_coverage,
      Distinct_Coverage  = m$skill_coverage,
      Overlap_50         = m$overlap_ge_50,
      Matched_Count      = length(m$matched_skills),
      Missing_Count      = length(m$missing_skills),
      Median_Salary      = med_sal,
      stringsAsFactors   = FALSE
    )
  })

  results_df <- do.call(rbind, match_list)

  # Rank primarily by Posting Overlap (>=80%), secondarily by Weighted Coverage
  results_df <- results_df |>
    dplyr::arrange(dplyr::desc(Posting_Overlap_80), dplyr::desc(Weighted_Coverage))

  results_df
}

# -----------------------------------------------------------------------------
# 7. compare_career_paths()
# Side-by-side comparative analysis between Role A and Role B
# -----------------------------------------------------------------------------
compare_career_paths <- function(df, role_a, role_b, candidate_skills = NULL) {
  candidate_skills <- normalize_candidate_skills(candidate_skills)

  if (role_a == role_b) {
    return(list(
      is_same_role = TRUE,
      error_msg    = "Role A and Role B are identical. Please select two distinct roles to compare career trajectories."
    ))
  }

  fit_a <- calculate_candidate_role_match(df, candidate_skills, role_a)
  fit_b <- calculate_candidate_role_match(df, candidate_skills, role_b)

  df_a <- df |> dplyr::filter(as.character(job_title) == role_a)
  df_b <- df |> dplyr::filter(as.character(job_title) == role_b)

  skills_a_all <- calculate_role_skill_demand(df, role_a)
  skills_b_all <- calculate_role_skill_demand(df, role_b)

  # Top 15 skills for presentation
  skills_a_top <- head(skills_a_all, 15)
  skills_b_top <- head(skills_b_all, 15)

  # Shared transferable skills across both roles
  shared_skills <- intersect(skills_a_all$skill, skills_b_all$skill)

  # Candidate coverage on shared skills
  candidate_shared_matched <- intersect(candidate_skills, shared_skills)
  candidate_shared_missing <- setdiff(shared_skills, candidate_skills)

  # Role-specific distinct competencies
  unique_to_a <- setdiff(skills_a_all$skill, skills_b_all$skill)
  unique_to_b <- setdiff(skills_b_all$skill, skills_a_all$skill)

  list(
    is_same_role             = FALSE,
    role_a                   = role_a,
    role_b                   = role_b,
    postings_a               = nrow(df_a),
    postings_b               = nrow(df_b),
    salary_a                 = fit_a$salary_context,
    salary_b                 = fit_b$salary_context,
    exp_mean_a               = round(mean(df_a$experience_years, na.rm = TRUE), 1),
    exp_mean_b               = round(mean(df_b$experience_years, na.rm = TRUE), 1),
    fit_a                    = fit_a,
    fit_b                    = fit_b,
    skills_a_top             = skills_a_top,
    skills_b_top             = skills_b_top,
    shared_skills            = shared_skills,
    unique_to_a              = unique_to_a,
    unique_to_b              = unique_to_b,
    candidate_shared_matched = candidate_shared_matched,
    candidate_shared_missing = candidate_shared_missing
  )
}

# -----------------------------------------------------------------------------
# 8. simulate_profile_change()
# Recalculates before-and-after metrics between Current and Proposed profiles
# -----------------------------------------------------------------------------
simulate_profile_change <- function(df, current_skills, proposed_skills, target_role) {
  base_fit <- calculate_candidate_role_match(df, current_skills, target_role)
  prop_fit <- calculate_candidate_role_match(df, proposed_skills, target_role)

  current_skills  <- normalize_candidate_skills(current_skills)
  proposed_skills <- normalize_candidate_skills(proposed_skills)

  newly_added_skills   <- setdiff(proposed_skills, current_skills)
  newly_removed_skills <- setdiff(current_skills, proposed_skills)
  newly_matched_skills <- intersect(newly_added_skills, base_fit$missing_skills)

  # Count postings newly satisfying the 80% threshold
  base_overlaps <- calculate_posting_skill_overlap(df, current_skills, target_role)
  prop_overlaps <- calculate_posting_skill_overlap(df, proposed_skills, target_role)

  newly_satisfied_postings <- sum(base_overlaps < 80.0 & prop_overlaps >= 80.0)

  list(
    target_role               = target_role,
    baseline_coverage         = base_fit$skill_coverage,
    proposed_coverage         = prop_fit$skill_coverage,
    coverage_delta            = round(prop_fit$skill_coverage - base_fit$skill_coverage, 1),

    baseline_weighted_cov     = base_fit$weighted_coverage,
    proposed_weighted_cov     = prop_fit$weighted_coverage,
    weighted_coverage_delta   = round(prop_fit$weighted_coverage - base_fit$weighted_coverage, 1),

    baseline_overlap          = base_fit$posting_overlap,
    proposed_overlap          = prop_fit$posting_overlap,
    overlap_delta             = round(prop_fit$posting_overlap - base_fit$posting_overlap, 1),

    baseline_overlap_50       = base_fit$overlap_ge_50,
    proposed_overlap_50       = prop_fit$overlap_ge_50,

    baseline_overlap_100      = base_fit$overlap_eq_100,
    proposed_overlap_100      = prop_fit$overlap_eq_100,

    baseline_matched_count    = length(base_fit$matched_skills),
    proposed_matched_count    = length(prop_fit$matched_skills),

    newly_added_skills        = newly_added_skills,
    newly_removed_skills      = newly_removed_skills,
    newly_matched_role_skills = newly_matched_skills,
    newly_satisfied_postings  = newly_satisfied_postings,

    remaining_missing_tbl     = prop_fit$missing_skills_tbl,
    salary_context            = base_fit$salary_context
  )
}

# Alias for backwards compatibility
simulate_what_if <- simulate_profile_change
