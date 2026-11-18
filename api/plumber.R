# =============================================================================
# api/plumber.R
# CareerLens 2.0 — Statistical Intelligence Engine (R Plumber API)
# ITA04: Statistics with R Programming
# -----------------------------------------------------------------------------
# Exposes clean, high-performance JSON endpoints for Node.js backend.
# Loads dataset and precomputes analytical models once at startup.
# =============================================================================

suppressPackageStartupMessages({
  library(plumber)
  library(jsonlite)
  library(dplyr)
  library(tidyr)
  library(readr)
  library(stringr)
})

# Ensure working directory is project root
if (!file.exists("R/helper_functions.R") && file.exists("../R/helper_functions.R")) {
  setwd("..")
}

# Source existing R analytical modules
source("R/helper_functions.R")
source("R/data_cleaning.R")
source("R/skill_analysis.R")
source("R/salary_analysis.R")
source("R/model_validation.R")
source("R/regression_analysis.R")
source("R/career_fit.R")
source("R/recommendation_engine.R")
source("R/job_description_analysis.R")

message("[CareerLens R Service] Loading clean dataset and precomputing analytical assets...")

df_clean <- load_and_clean()
qr       <- data_quality_report()

# Pre-compile skill dictionary and unique lists
skill_dict       <- build_skill_dictionary(df_clean)
skill_demand_all <- skill_dict$demand_tbl
all_skills_vec   <- skill_dict$skills_vec

# Pre-train regression models (80/20 train/test split, seed = 42)
slr_res   <- run_simple_regression(df_clean)
mlr_res   <- run_multiple_regression(df_clean)
logit_res <- run_logistic_regression(df_clean)

message(sprintf("[CareerLens R Service] Ready. %d clean records, %d unique skills.", nrow(df_clean), length(all_skills_vec)))

#* @apiTitle CareerLens 2.0 Analytics Service
#* @apiDescription R Statistical Engine for Career Matching, Skill Gap Analysis & Regression Modeling

#* @plumber
function(pr) {
  pr$setSerializer(plumber::serializer_json(auto_unbox = TRUE))
}

#* CORS Filter
#* @filter cors
function(req, res) {
  res$setHeader("Access-Control-Allow-Origin", "*")
  res$setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
  res$setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization")
  if (req$REQUEST_METHOD == "OPTIONS") {
    res$status <- 200
    return(list())
  }
  plumber::forward()
}

#* Health check
#* @get /health
#* @serializer json
function() {
  list(
    status = "healthy",
    records = nrow(df_clean),
    skills = length(all_skills_vec),
    timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ")
  )
}

#* Metadata options for dropdowns & filters
#* @get /metadata
#* @serializer json
function() {
  roles <- sort(unique(as.character(df_clean$job_title)))
  locations <- sort(unique(as.character(df_clean$location)))
  industries <- sort(unique(as.character(df_clean$industry)))
  educations <- sort(unique(as.character(df_clean$education)))
  educations <- educations[!is.na(educations) & nzchar(educations)]
  if (length(educations) == 0) {
    educations <- c("B.Tech", "B.E.", "BCA", "MCA", "M.Tech", "MBA", "B.Sc", "M.Sc", "Ph.D")
  }
  company_sizes <- c("Small", "Medium", "Large", "Enterprise")
  
  list(
    roles = roles,
    locations = locations,
    industries = industries,
    educations = educations,
    company_sizes = company_sizes,
    skills = all_skills_vec
  )
}

#* Overall Market Overview & Aggregate KPIs
#* @get /market/overview
#* @serializer json
function(location = "All", role = "All", industry = "All") {
  df <- df_clean
  if (!is.null(location) && location != "All") df <- df[df$location == location, ]
  if (!is.null(role) && role != "All") df <- df[as.character(df$job_title) == role, ]
  if (!is.null(industry) && industry != "All") df <- df[as.character(df$industry) == industry, ]
  
  total_postings <- nrow(df)
  sal_valid <- df$salary_inr[!is.na(df$salary_inr)]
  
  avg_salary <- if (length(sal_valid) > 0) round(mean(sal_valid)) else 0
  median_salary <- if (length(sal_valid) > 0) round(median(sal_valid)) else 0
  
  # Top skills
  top_skills <- head(calculate_skill_demand(df), 10)
  
  # Top roles
  top_roles <- df |>
    dplyr::count(job_title, name = "count") |>
    dplyr::arrange(dplyr::desc(count)) |>
    head(10)
    
  # Top locations
  top_locations <- df |>
    dplyr::count(location, name = "count") |>
    dplyr::arrange(dplyr::desc(count)) |>
    head(10)
    
  list(
    total_postings = total_postings,
    avg_salary = avg_salary,
    median_salary = median_salary,
    top_skills = top_skills,
    top_roles = top_roles,
    top_locations = top_locations
  )
}

#* Skills Demand Distribution
#* @get /market/skills
#* @serializer json
function(top = 25, role = "All") {
  top_n <- as.integer(top)
  if (is.na(top_n) || top_n <= 0) top_n <- 25
  
  if (!is.null(role) && role != "All") {
    res <- role_skill_demand(df_clean, role, top_n = top_n)
  } else {
    res <- head(calculate_skill_demand(df_clean), top_n)
  }
  res
}

#* Salary Distribution and Boxplots by Role
#* @get /market/salary
#* @serializer json
function() {
  sal_df <- df_clean |>
    dplyr::filter(!is.na(salary_inr), salary_outlier == 0)
    
  top_roles <- names(head(sort(table(sal_df$job_title), decreasing = TRUE), 8))
  
  stats_by_role <- lapply(top_roles, function(r) {
    sals <- sal_df$salary_inr[sal_df$job_title == r]
    list(
      role = r,
      count = length(sals),
      median = round(median(sals)),
      mean = round(mean(sals)),
      q1 = round(quantile(sals, 0.25)),
      q3 = round(quantile(sals, 0.75)),
      min = round(min(sals)),
      max = round(max(sals))
    )
  })
  
  stats_by_role
}

#* Correlation Analysis
#* @get /market/correlation
#* @serializer json
function() {
  cor_sub <- df_clean |>
    dplyr::filter(!is.na(salary_inr), !is.na(experience_years)) |>
    dplyr::select(
      experience_years,
      salary_inr,
      skill_count,
      company_size_num
    )
  
  mat <- round(cor(cor_sub, method = "pearson"), 3)
  
  list(
    matrix = as.data.frame(mat),
    variables = colnames(mat)
  )
}

#* Candidate Career Matches Shortlist
#* @post /analyze/career-matches
#* @serializer json
function(req) {
  body <- tryCatch(jsonlite::fromJSON(req$postBody), error = function(e) list())
  skills <- if (!is.null(body$skills)) body$skills else c("Python", "SQL", "Excel")
  min_postings <- if (!is.null(body$min_postings)) as.integer(body$min_postings) else 50
  
  ranked <- rank_career_matches(df_clean, skills, min_postings = min_postings)
  ranked
}

#* Detailed Match for a Specific Role
#* @post /analyze/career-detail
#* @serializer json
function(req) {
  body <- tryCatch(jsonlite::fromJSON(req$postBody), error = function(e) list())
  skills <- if (!is.null(body$skills)) body$skills else c("Python", "SQL", "Excel")
  role <- if (!is.null(body$role)) body$role else "Data Analyst"
  exp <- if (!is.null(body$experience)) as.numeric(body$experience) else 2
  
  match_res <- calculate_candidate_role_match(df_clean, skills, role, candidate_exp = exp)
  match_res
}

#* Compare Career Paths (Role A vs Role B)
#* @post /analyze/career-comparison
#* @serializer json
function(req) {
  body <- tryCatch(jsonlite::fromJSON(req$postBody), error = function(e) list())
  skills <- if (!is.null(body$skills)) body$skills else c("Python", "SQL", "Excel")
  role_a <- if (!is.null(body$role_a)) body$role_a else "Data Analyst"
  role_b <- if (!is.null(body$role_b)) body$role_b else "Data Scientist"
  
  cmp_res <- compare_career_paths(df_clean, role_a, role_b, skills)
  cmp_res
}

#* Prioritized Skill Gaps & Recommendations
#* @post /analyze/skill-gap
#* @serializer json
function(req) {
  body <- tryCatch(jsonlite::fromJSON(req$postBody), error = function(e) list())
  skills <- if (!is.null(body$skills)) body$skills else c("Python", "SQL", "Excel")
  role <- if (!is.null(body$role)) body$role else "Data Analyst"
  
  rec_res <- calculate_recommendation_priorities(df_clean, skills, role)
  rec_res
}

#* What-If Simulation
#* @post /simulate/skills
#* @serializer json
function(req) {
  body <- tryCatch(jsonlite::fromJSON(req$postBody), error = function(e) list())
  current_skills <- if (!is.null(body$current_skills)) body$current_skills else c("Python", "SQL", "Excel")
  proposed_skills <- if (!is.null(body$proposed_skills)) body$proposed_skills else c("Python", "SQL", "Excel", "Power BI")
  role <- if (!is.null(body$role)) body$role else "Data Analyst"
  
  sim_res <- simulate_profile_change(df_clean, current_skills, proposed_skills, role)
  sim_res
}

#* Job Description Analysis
#* @post /analyze/job-description
#* @serializer json
function(req) {
  body <- tryCatch(jsonlite::fromJSON(req$postBody), error = function(e) list())
  text <- if (!is.null(body$text)) body$text else ""
  candidate_skills <- if (!is.null(body$candidate_skills)) body$candidate_skills else c("Python", "SQL", "Excel")
  target_role <- if (!is.null(body$target_role)) body$target_role else "Data Analyst"
  
  jd_res <- analyze_job_description(text, candidate_skills, target_role, df_clean, skill_dict)
  jd_res
}

#* Salary Prediction & Diagnostics
#* @post /predict/salary
#* @serializer json
function(req) {
  body <- tryCatch(jsonlite::fromJSON(req$postBody), error = function(e) list())
  exp_years <- if (!is.null(body$experience)) as.numeric(body$experience) else 4
  skill_cnt <- if (!is.null(body$skill_count)) as.integer(body$skill_count) else 6
  edu_val <- if (!is.null(body$education)) body$education else "B.Tech"
  comp_size <- if (!is.null(body$company_size)) body$company_size else "Large"
  loc_tier <- if (!is.null(body$location_tier)) body$location_tier else "Tier 1"
  
  pred_res <- tryCatch(
    predict_salary_scenario(slr_res, mlr_res, logit_res, exp_years, skill_cnt, edu_val, comp_size, loc_tier),
    error = function(e) {
      message("[CareerLens] predict_salary_scenario error: ", e$message)
      list(error = e$message, slr_estimate = NA_real_, mlr_estimate = NA_real_, high_sal_prob = NA_real_)
    }
  )

  # Convert test_cm (class: table) -> plain nested list so jsonlite can serialize it
  cm_tbl <- logit_res$test_cm
  cm_list <- if (inherits(cm_tbl, "table")) {
    cm_df <- as.data.frame.matrix(cm_tbl)
    setNames(
      lapply(rownames(cm_df), function(r) as.list(cm_df[r, , drop = FALSE][1, ])),
      rownames(cm_df)
    )
  } else {
    list()
  }

  # Strip the cm table from test_metrics (also a table, cannot serialize)
  test_met <- logit_res$test_metrics
  test_met$cm <- NULL

  list(
    prediction = pred_res,
    slr_summary = list(
      equation  = slr_res$equation,
      train_r2  = slr_res$train_r2,
      test_r2   = slr_res$test_r2,
      test_rmse = slr_res$test_rmse,
      test_mae  = slr_res$test_mae
    ),
    mlr_summary = list(
      train_r2  = mlr_res$train_r2,
      adj_r2    = mlr_res$train_adj_r2,
      test_r2   = mlr_res$test_r2,
      test_rmse = mlr_res$test_rmse,
      test_mae  = mlr_res$test_mae,
      f_stat    = mlr_res$f_stat
    ),
    logit_summary = list(
      threshold    = round(logit_res$threshold),
      test_metrics = test_met,
      test_cm      = cm_list,
      aic          = logit_res$aic
    )
  )
}

#* Data Quality Audit & Summary
#* @get /data-quality
#* @serializer json
function() {
  na_df <- data.frame(
    column = names(qr$na_counts),
    missing_count = as.integer(qr$na_counts),
    missing_pct = round(as.integer(qr$na_counts) / qr$raw_rows * 100, 1),
    stringsAsFactors = FALSE
  ) |>
    dplyr::filter(missing_count > 0) |>
    dplyr::arrange(dplyr::desc(missing_count))
    
  preview <- head(df_clean, 50) |>
    dplyr::select(job_id, job_title, company, location, experience_years, education, salary_inr, skills, employment_type, remote_type)
    
  list(
    summary = list(
      raw_rows = qr$raw_rows,
      raw_cols = qr$raw_cols,
      clean_rows = qr$clean_rows,
      clean_cols = qr$clean_cols,
      duplicates_removed = qr$n_dupes,
      total_missing_handled = qr$total_na,
      missing_salaries_preserved = qr$salary_missing_count,
      valid_salaries_analyzed = qr$salary_valid_count
    ),
    missing_by_column = na_df,
    preview = preview
  )
}
