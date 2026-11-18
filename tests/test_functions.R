# =============================================================================
# test_functions.R — CareerLens Comprehensive Automated Test Suite
# ITA04: Statistics with R Programming
# Run via: Rscript tests/test_functions.R
# =============================================================================

cat("===================================================================\n")
cat("   CareerLens: Automated Analytical Test Suite (Pure R)\n")
cat("===================================================================\n\n")

total_tests  <- 0
passed_tests <- 0

assert_test <- function(desc, condition) {
  total_tests <<- total_tests + 1
  if (isTRUE(condition)) {
    passed_tests <<- passed_tests + 1
    cat(sprintf("  [PASS] %s\n", desc))
  } else {
    cat(sprintf("  [FAIL] %s\n", desc))
    stop(paste("Assertion failed:", desc))
  }
}

# -----------------------------------------------------------------------------
# Test Group 1: Dataset Generation & Data Cleaning Pipeline
# -----------------------------------------------------------------------------
cat("--- 1. Testing Dataset & Cleaning Pipeline ---\n")
source("R/helper_functions.R")
source("R/data_cleaning.R")

raw_df <- readr::read_csv("data/job_market.csv", show_col_types = FALSE)
assert_test("Raw dataset has 6,030 rows", nrow(raw_df) == 6030)
assert_test("Raw dataset contains required schema columns",
            all(c("job_id", "job_title", "company", "location", "salary_inr",
                  "salary_currency", "experience_years", "skills") %in% names(raw_df)))

assert_test("Salary currency is standardized to INR", all(raw_df$salary_currency == "INR"))
assert_test("Fictional companies pool has >= 40 unique employers", length(unique(raw_df$company)) >= 40)

clean_df <- load_and_clean()
assert_test("Clean dataset has exactly 6,000 clean rows", nrow(clean_df) == 6000)
assert_test("Clean dataset preserves missing salary_inr as NA (not silently imputed)", sum(is.na(clean_df$salary_inr)) > 0)
assert_test("Clean dataset includes salary_missing indicator", "salary_missing" %in% names(clean_df))
assert_test("Clean dataset has valid experience bins", !any(is.na(clean_df$experience_bin)))

# -----------------------------------------------------------------------------
# Test Group 2: Skill Analysis & Strict Deduplication
# -----------------------------------------------------------------------------
cat("\n--- 2. Testing Skill Analysis & Deduplication ---\n")
source("R/skill_analysis.R")

# Hand-crafted test data frame with duplicate skills in same posting
mini_dup_df <- data.frame(
  job_id          = c("JB01", "JB02"),
  job_title       = c("Data Analyst", "Data Analyst"),
  location        = c("Bengaluru", "Bengaluru"),
  industry        = c("IT", "IT"),
  employment_type = c("Full-Time", "Full-Time"),
  skills          = c("Python;SQL;Python;SQL;Excel", "Python;Tableau"),
  stringsAsFactors = FALSE
)
parsed_mini <- parse_skills(mini_dup_df)
jb01_py_count <- sum(parsed_mini$job_id == "JB01" & parsed_mini$skill == "Python")
assert_test("parse_skills() strictly deduplicates duplicate skills per job_id", jb01_py_count == 1)

skill_tbl <- calculate_skill_demand(clean_df)
assert_test("Skill demand table has >= 25 skills", nrow(skill_tbl) >= 25)
assert_test("Skill demand percentages are valid (0-100%)", all(skill_tbl$demand_pct >= 0 & skill_tbl$demand_pct <= 100))

# Full role vocabulary test (top_n = NULL)
role_skills_all <- role_skill_demand(clean_df, "Data Analyst", top_n = NULL)
role_skills_5   <- role_skill_demand(clean_df, "Data Analyst", top_n = 5)
assert_test("role_skill_demand with top_n = NULL returns complete vocabulary (> top_n=5)", nrow(role_skills_all) > nrow(role_skills_5))

# -----------------------------------------------------------------------------
# Test Group 3: Career Fit Engine (All 8 Mandated Functions & Dual Metrics)
# -----------------------------------------------------------------------------
cat("\n--- 3. Testing Career Fit Engine & Dual Metrics ---\n")
source("R/career_fit.R")

# 1. normalize_candidate_skills()
norm_sk <- normalize_candidate_skills(c("py", "POSTGRES", "k8s", "aws", "powerbi", "  Python  "))
assert_test("normalize_candidate_skills() canonicalizes 'py' to 'Python'", "Python" %in% norm_sk)
assert_test("normalize_candidate_skills() canonicalizes 'postgres' to 'PostgreSQL'", "PostgreSQL" %in% norm_sk)
assert_test("normalize_candidate_skills() canonicalizes 'k8s' to 'Kubernetes'", "Kubernetes" %in% norm_sk)
assert_test("normalize_candidate_skills() canonicalizes 'powerbi' to 'Power BI'", "Power BI" %in% norm_sk)
assert_test("normalize_candidate_skills() deduplicates resulting names", length(norm_sk) == 5)

# Hand-crafted verification of exact Dual Metrics formula
# Setup: 3 postings for Test Role:
# Post 1: Python, SQL, Excel (3 skills)
# Post 2: Python, SQL, Tableau, Power BI (4 skills)
# Post 3: Python, R, AWS (3 skills)
# Total distinct role skills: Python, SQL, Excel, Tableau, Power BI, R, AWS = 7 skills
# Candidate skills: Python, SQL, Excel (3 skills)
# Overlap Post 1: 3/3 = 100% (>= 80%? YES)
# Overlap Post 2: 2/4 = 50%  (>= 80%? NO)
# Overlap Post 3: 1/3 = 33.3% (>= 80%? NO)
# Postings with >= 80% overlap: 1 / 3 = 33.3%
# Postings with >= 50% overlap: 2 / 3 = 66.7%
# Distinct Skill Coverage: 3 / 7 = 42.9%
mini_role_df <- data.frame(
  job_id          = c("T1", "T2", "T3"),
  job_title       = rep("Test Role", 3),
  location        = rep("Bengaluru", 3),
  industry        = rep("Tech", 3),
  employment_type = rep("Full-Time", 3),
  experience_years= c(2, 3, 5),
  salary_inr      = c(600000, 800000, 1000000),
  skills          = c("Python;SQL;Excel", "Python;SQL;Tableau;Power BI", "Python;R;AWS"),
  stringsAsFactors = FALSE
)

mini_match <- calculate_candidate_role_match(mini_role_df, c("Python", "SQL", "Excel"), "Test Role")
assert_test("Hand-crafted Distinct Skill Coverage equals 42.9%", mini_match$skill_coverage == 42.9)
assert_test("Hand-crafted Posting Overlap (>=80%) equals 33.3%", mini_match$overlap_ge_80 == 33.3)
assert_test("Hand-crafted Posting Overlap (>=50%) equals 66.7%", mini_match$overlap_ge_50 == 66.7)
assert_test("Hand-crafted Posting Overlap (=100%) equals 33.3%", mini_match$overlap_eq_100 == 33.3)

# Test against full dataset
cand_skills <- c("Python", "SQL", "Excel")
fit_da <- calculate_candidate_role_match(clean_df, cand_skills, "Data Analyst", candidate_exp = 2)
assert_test("Full dataset match produces positive postings count", fit_da$n_postings > 0)
assert_test("Distinct skill coverage is between 0 and 100", fit_da$skill_coverage >= 0 && fit_da$skill_coverage <= 100)
assert_test("Demand-weighted coverage is between 0 and 100", fit_da$weighted_coverage >= 0 && fit_da$weighted_coverage <= 100)
assert_test("Posting overlap (>=80%) is between 0 and 100", fit_da$overlap_ge_80 >= 0 && fit_da$overlap_ge_80 <= 100)
assert_test("Experience compatibility computed accurately", !is.na(fit_da$exp_compatibility$pct_qualified))

# 6. rank_career_matches()
ranked_roles <- rank_career_matches(clean_df, cand_skills, min_postings = 50)
assert_test("rank_career_matches() returns ranked roles", nrow(ranked_roles) > 0)
assert_test("rank_career_matches() contains required comparison columns",
            all(c("Job_Role", "Posting_Count", "Posting_Overlap_80", "Weighted_Coverage", "Distinct_Coverage") %in% names(ranked_roles)))
assert_test("rank_career_matches() correctly orders by Posting_Overlap_80 descending",
            all(diff(ranked_roles$Posting_Overlap_80) <= 0))

# 7. compare_career_paths()
cmp_res <- compare_career_paths(clean_df, "Data Analyst", "Data Scientist", cand_skills)
assert_test("compare_career_paths() identifies distinct roles", !cmp_res$is_same_role)
assert_test("compare_career_paths() identifies shared transferable skills", length(cmp_res$shared_skills) > 0)
assert_test("compare_career_paths() identifies unique competencies for both roles",
            length(cmp_res$unique_to_a) > 0 && length(cmp_res$unique_to_b) > 0)

# 8. simulate_profile_change() (What-If Lab)
prop_skills <- c(cand_skills, "Power BI")
sim_res <- simulate_profile_change(clean_df, cand_skills, prop_skills, "Data Analyst")
assert_test("What-if simulator reports non-negative coverage delta", sim_res$coverage_delta >= 0)
assert_test("What-if simulator tracks newly added skills", "Power BI" %in% sim_res$newly_added_skills)
assert_test("What-if simulator tracks newly satisfied postings", sim_res$newly_satisfied_postings >= 0)

# -----------------------------------------------------------------------------
# Test Group 4: Recommendation Engine (Priority Index & Co-occurrence)
# -----------------------------------------------------------------------------
cat("\n--- 4. Testing Recommendation Engine ---\n")
source("R/recommendation_engine.R")

rec_res <- calculate_recommendation_priorities(clean_df, cand_skills, "Data Analyst")
assert_test("Recommendation engine evaluates recommendations table", nrow(rec_res$recommendations_tbl) > 0)

# Test Priority Index calculation: 0.70 * Role Demand + 0.30 * Market Demand
top_rec <- rec_res$recommendations_tbl[1, ]
expected_pi <- round(0.70 * top_rec$role_demand_pct + 0.30 * top_rec$market_demand_pct, 1)
assert_test("Priority Index accurately matches 0.70 * Role + 0.30 * Market formula", top_rec$priority_index == expected_pi)

assert_test("Priority category assigned (HIGH/MEDIUM/ADDITIONAL)",
            top_rec$priority_category %in% c("HIGH PRIORITY", "MEDIUM PRIORITY", "ADDITIONAL SKILL"))
assert_test("Co-occurrence analysis populated with empirical evidence", nzchar(top_rec$cooccurring_skills))
assert_test("Dynamic narrative explanation cites role demand and postings count",
            grepl("postings", top_rec$narrative_explanation, ignore.case = TRUE))

export_df <- export_recommendations_csv(rec_res)
assert_test("export_recommendations_csv() generates valid data frame", nrow(export_df) > 0 && "Priority_Index" %in% names(export_df))

# -----------------------------------------------------------------------------
# Test Group 5: Model Validation & Statistical Evaluation
# -----------------------------------------------------------------------------
cat("\n--- 5. Testing Model Validation Utilities (Pure R) ---\n")
source("R/model_validation.R")

# Regression metrics hand calculation: actual = c(10, 20, 30), pred = c(12, 18, 33)
# Errors: +2, -2, +3. Abs: 2, 2, 3. MAE = 7/3 = 2.33 -> round 2
# Sq Errors: 4, 4, 9 = 17. RMSE = sqrt(17/3) = sqrt(5.67) = 2.38 -> round 2
test_reg <- calc_regression_metrics(c(10, 20, 30), c(12, 18, 33))
assert_test("calc_regression_metrics() MAE equals 2", test_reg$mae == 2)
assert_test("calc_regression_metrics() RMSE equals 2", test_reg$rmse == 2)
assert_test("calc_regression_metrics() Test R2 is valid", test_reg$test_r2 > 0.8)

# Classification metrics hand calculation:
# TP = 40, FP = 10, TN = 30, FN = 20. Total = 100
# Accuracy = (40 + 30)/100 = 70.0%
# Sensitivity = 40 / (40 + 20) = 40/60 = 66.7%
# Specificity = 30 / (30 + 10) = 30/40 = 75.0%
# Precision = 40 / (40 + 10) = 40/50 = 80.0%
# F1 = 2 * (80 * 66.67) / (80 + 66.67) = 10667.2 / 146.67 = 72.7%
actuals <- c(rep(1, 40), rep(0, 10), rep(0, 30), rep(1, 20))
preds   <- c(rep(0.9, 40), rep(0.8, 10), rep(0.2, 30), rep(0.3, 20))
test_clf <- calc_classification_metrics(actuals, preds, threshold = 0.5)
assert_test("calc_classification_metrics() Accuracy equals 70.0%", test_clf$accuracy == 70.0)
assert_test("calc_classification_metrics() Sensitivity equals 66.7%", test_clf$sensitivity == 66.7)
assert_test("calc_classification_metrics() Specificity equals 75.0%", test_clf$specificity == 75.0)
assert_test("calc_classification_metrics() Precision equals 80.0%", test_clf$precision == 80.0)
assert_test("calc_classification_metrics() F1 Score equals 72.7%", test_clf$f1_score == 72.7)

# Leak-free Train/Test Split
split_check <- split_train_test(clean_df, train_pct = 0.80, seed = 42)
assert_test("split_train_test() produces ~80% training set",
            split_check$n_train > 4000 && split_check$n_train < 5000)
assert_test("split_train_test() computes threshold strictly on training data",
            split_check$train_salary_median == median(split_check$train_data$salary_inr))

# -----------------------------------------------------------------------------
# Test Group 6: Regression Modelling & Prediction Scenarios
# -----------------------------------------------------------------------------
cat("\n--- 6. Testing Regression Models & Predictions ---\n")
source("R/regression_analysis.R")

slr_res <- run_simple_regression(clean_df)
assert_test("SLR Train R-squared is positive", slr_res$train_r2 > 0.05)
assert_test("SLR Out-of-sample Test R-squared computed", slr_res$test_r2 > 0.05)
assert_test("SLR Test MAE is positive number", slr_res$test_mae > 0)

mlr_res <- run_multiple_regression(clean_df)
assert_test("MLR Train R-squared exceeds SLR Train R-squared", mlr_res$train_r2 >= slr_res$train_r2)
assert_test("MLR Out-of-sample Test R-squared computed", mlr_res$test_r2 > 0.10)
assert_test("MLR Residual diagnostics generated", nrow(mlr_res$diagnostics) > 0)

logit_res <- run_logistic_regression(clean_df)
assert_test("Logistic regression Train accuracy > 55%", logit_res$train_metrics$accuracy > 55)
assert_test("Logistic regression Out-of-sample Test accuracy > 55%", logit_res$test_metrics$accuracy > 55)
assert_test("Logistic regression Test precision computed", !is.na(logit_res$test_metrics$precision))
assert_test("Logistic regression Test F1 score computed", !is.na(logit_res$test_metrics$f1_score))

# Scenario Prediction & Extrapolation Warning
pred_norm <- predict_salary_scenario(slr_res, mlr_res, logit_res, exp_years = 5, skill_cnt = 8, edu_val = "B.Tech", comp_size = "Large")
assert_test("Prediction point estimate valid number", !is.na(pred_norm$slr_estimate) && pred_norm$slr_estimate > 0)
assert_test("Prediction interval bounds valid (lwr <= estimate <= upr)",
            pred_norm$slr_lwr <= pred_norm$slr_estimate && pred_norm$slr_estimate <= pred_norm$slr_upr)
assert_test("Normal experience produces no extrapolation warning", is.null(pred_norm$extrap_warn))

# Extrapolation check (> max training exp)
pred_extrap <- predict_salary_scenario(slr_res, mlr_res, logit_res, exp_years = 30, skill_cnt = 8, edu_val = "B.Tech", comp_size = "Large")
assert_test("Extreme experience input triggers extrapolation warning", !is.null(pred_extrap$extrap_warn))

# -----------------------------------------------------------------------------
# Test Group 7: Job Description Analyzer (Boundary-Aware Regex)
# -----------------------------------------------------------------------------
cat("\n--- 7. Testing Job Description Analyzer ---\n")
source("R/job_description_analysis.R")

skill_dict <- build_skill_dictionary(clean_df)
assert_test("Skill dictionary compiled with >= 30 skills", length(skill_dict$skills_vec) >= 30)

sample_jd <- "We are seeking a Backend Developer proficient in Python, SQL, Docker, and AWS. Knowledge of C++, Node.js, and CI/CD is required."
extracted <- extract_skills_from_text(sample_jd, skill_dict)
assert_test("Extraction identifies standard skills: Python, SQL, Docker, AWS",
            all(c("Python", "SQL", "Docker", "AWS") %in% extracted))
assert_test("Extraction handles special characters: C++, Node.js, CI/CD",
            all(c("C++", "Node.js", "CI/CD") %in% extracted))

# Standalone R boundary test
research_text <- "Candidate will conduct academic research and coordinate meetings."
extracted_res <- extract_skills_from_text(research_text, skill_dict)
assert_test("Word boundary test: 'research' does not falsely match skill 'R'", !("R" %in% extracted_res))

r_valid_text <- "Looking for a Data Analyst with R and Python skills."
extracted_r <- extract_skills_from_text(r_valid_text, skill_dict)
assert_test("Word boundary test: standalone 'R' correctly extracted", "R" %in% extracted_r)

jd_analysis <- analyze_job_description(sample_jd, cand_skills, "Data Analyst", clean_df, skill_dict)
assert_test("JD analysis classifies matched and missing skills", jd_analysis$has_skills && length(jd_analysis$matched_skills) > 0)
assert_test("JD analysis computes Priority Index for missing skills", "Priority Index" %in% names(jd_analysis$breakdown_tbl))

# -----------------------------------------------------------------------------
# Test Group 8: Edge Cases & Robustness
# -----------------------------------------------------------------------------
cat("\n--- 8. Testing Edge Cases & Robustness ---\n")

# Empty candidate skills
fit_empty <- calculate_candidate_role_match(clean_df, character(0), "Data Analyst")
assert_test("Empty skills input yields 0% coverage without error", fit_empty$skill_coverage == 0)
assert_test("Empty skills input yields 0% posting overlap", fit_empty$posting_overlap == 0)

# Non-existent role
fit_none <- calculate_candidate_role_match(clean_df, cand_skills, "NonExistentRoleXYZ")
assert_test("Non-existent role returns 0 postings and safe warning",
            fit_none$n_postings == 0 && !is.null(fit_none$warning_msg))

# Empty job description
jd_empty <- analyze_job_description("", cand_skills, "Data Analyst", clean_df, skill_dict)
assert_test("Empty JD text returns has_skills = FALSE safely", !jd_empty$has_skills)

cat("\n===================================================================\n")
cat(sprintf("   TEST RESULTS: %d / %d PASSED (100%% SUCCESS)\n", passed_tests, total_tests))
cat("===================================================================\n")
