# =============================================================================
# validate.R — CareerLens internal validation script
# Run this to verify the project works before demo
# =============================================================================

setwd("D:/Projects/Personal/Career Lens")
cat("=== CareerLens Validation ===\n\n")

# 1. Check dataset
cat("1. Checking raw dataset...\n")
df_raw <- readr::read_csv("data/job_market.csv", show_col_types=FALSE)
cat("   Rows:", nrow(df_raw), "| Cols:", ncol(df_raw), "\n")
stopifnot("Row count too low" = nrow(df_raw) >= 5000)
stopifnot("Column count wrong" = ncol(df_raw) >= 18)
cat("   PASS\n\n")

# 2. Load cleaning pipeline
cat("2. Running data cleaning pipeline...\n")
source("R/helper_functions.R")
source("R/data_cleaning.R")
df_clean <- load_and_clean(force_regen=TRUE)
cat("   Clean rows:", nrow(df_clean), "\n")
stopifnot("Clean rows too low" = nrow(df_clean) >= 4000)
stopifnot("Salary NAs remain" = sum(is.na(df_clean$salary_inr)) == 0)
cat("   PASS\n\n")

# 3. Skill analysis
cat("3. Testing skill analysis...\n")
source("R/skill_analysis.R")
sk <- calculate_skill_demand(df_clean)
stopifnot("Skill demand empty" = nrow(sk) > 10)
cat("   Top skill:", as.character(sk$skill[1]), "at", sk$demand_pct[1], "%\n")
cat("   PASS\n\n")

# 4. Salary analysis
cat("4. Testing salary analysis...\n")
source("R/salary_analysis.R")
ss <- calculate_salary_summary(df_clean)
cat("   Mean salary:", format_inr(ss$mean), "\n")
cat("   Median salary:", format_inr(ss$median), "\n")
stopifnot("Mean salary unrealistic" = ss$mean > 100000)
cat("   PASS\n\n")

# 5. Regression
cat("5. Testing regression models...\n")
source("R/regression_analysis.R")
slr <- run_simple_regression(df_clean)
cat("   SLR R²:", round(slr$r_squared, 4), "\n")
stopifnot("SLR R² too low" = slr$r_squared > 0.05)

mlr <- run_multiple_regression(df_clean)
cat("   MLR R²:", round(mlr$r_squared, 4), "\n")
stopifnot("MLR R² lower than SLR" = mlr$r_squared >= slr$r_squared)

logit <- run_logistic_regression(df_clean)
cat("   Logit accuracy:", logit$cm_summary$accuracy, "%\n")
stopifnot("Logit accuracy too low" = logit$cm_summary$accuracy > 50)
cat("   PASS\n\n")

# 6. Correlation
cat("6. Testing correlation matrix...\n")
cor_data <- df_clean |>
  dplyr::select(experience_years, salary_inr, skill_count, company_size_num) |>
  dplyr::filter(dplyr::if_all(dplyr::everything(), ~!is.na(.x)))
cm <- cor(cor_data, method="pearson")
cat("   experience_years ~ salary_inr: r =", round(cm["experience_years","salary_inr"], 3), "\n")
stopifnot("Correlation not computed" = !is.na(cm["experience_years","salary_inr"]))
cat("   PASS\n\n")

# 7. Data quality report
cat("7. Testing data quality report...\n")
qr <- data_quality_report()
cat("   Raw rows:", qr$raw_rows, "| Clean rows:", qr$clean_rows, "\n")
cat("   PASS\n\n")

cat("=== ALL VALIDATION CHECKS PASSED ===\n")
cat("Launch with: shiny::runApp()\n")
