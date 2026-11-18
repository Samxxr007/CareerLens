# =============================================================================
# regression_analysis.R
# CareerLens — ITA04: Statistics with R Programming
# -----------------------------------------------------------------------------
# Rigorous Regression Modelling with 80/20 Train/Test Evaluation:
#   1. run_simple_regression()    - lm(salary_inr ~ experience_years)
#   2. run_multiple_regression()  - MLR + Out-of-sample Test R2 & Residual Diagnostics
#   3. run_logistic_regression()  - glm(binomial) + Leak-free Training Threshold +
#                                   Out-of-sample Test Accuracy/CM/F1
#   4. predict_salary_scenario()  - Point estimate + 95% Prediction Interval
# =============================================================================

source("R/helper_functions.R")
source("R/model_validation.R")

# -----------------------------------------------------------------------------
# run_simple_regression()
# Simple linear regression: salary_inr ~ experience_years
# Evaluates on 80% Train / 20% Test partition (seed = 42)
# -----------------------------------------------------------------------------
run_simple_regression <- function(df) {
  split_res  <- split_train_test(df, train_pct = 0.80, seed = 42)
  train_data <- split_res$train_data
  test_data  <- split_res$test_data

  # Train model
  model <- lm(salary_inr ~ experience_years, data = train_data)
  summ  <- summary(model)

  # Out-of-sample test evaluation
  test_pred <- predict(model, newdata = test_data)
  val_res   <- calc_regression_metrics(test_data$salary_inr, test_pred)

  intercept <- coef(model)[["(Intercept)"]]
  slope     <- coef(model)[["experience_years"]]

  equation <- sprintf(
    "salary_inr = %s + %s \u00D7 experience_years",
    format(round(intercept), big.mark = ","),
    format(round(slope), big.mark = ",")
  )

  list(
    model          = model,
    train_data     = train_data,
    test_data      = test_data,
    intercept      = intercept,
    slope          = slope,
    train_r2       = round(summ$r.squared, 4),
    train_adj_r2   = round(summ$adj.r.squared, 4),
    test_r2        = val_res$test_r2,
    test_rmse      = val_res$rmse,
    test_mae       = val_res$mae,
    p_value        = summ$coefficients["experience_years", "Pr(>|t|)"],
    f_stat         = round(summ$fstatistic[1], 2),
    equation       = equation,
    coef_table     = as.data.frame(summ$coefficients),
    max_train_exp  = max(train_data$experience_years, na.rm = TRUE)
  )
}

# -----------------------------------------------------------------------------
# run_multiple_regression()
# Multiple linear regression with factor encoding and 80/20 train/test evaluation
# Predictors: experience_years, skill_count, education, company_size_num, location_tier
# -----------------------------------------------------------------------------
run_multiple_regression <- function(df) {
  split_res  <- split_train_test(df, train_pct = 0.80, seed = 42)
  train_data <- split_res$train_data |>
    dplyr::filter(
      !is.na(skill_count), !is.na(education),
      !is.na(company_size_num), !is.na(location_tier)
    ) |>
    dplyr::mutate(
      education     = droplevels(as.factor(as.character(education))),
      location_tier = as.factor(location_tier)
    )

  test_data <- split_res$test_data |>
    dplyr::filter(
      !is.na(skill_count), !is.na(education),
      !is.na(company_size_num), !is.na(location_tier)
    ) |>
    dplyr::mutate(
      education     = factor(as.character(education), levels = levels(train_data$education)),
      location_tier = factor(as.character(location_tier), levels = levels(train_data$location_tier))
    )

  model <- lm(
    salary_inr ~ experience_years + skill_count + education + company_size_num + location_tier,
    data = train_data
  )
  summ <- summary(model)

  # Out-of-sample test evaluation
  test_pred <- predict(model, newdata = test_data)
  val_res   <- calc_regression_metrics(test_data$salary_inr, test_pred)

  # Residual diagnostics dataframe
  diagnostics <- data.frame(
    Fitted    = fitted(model),
    Residuals = resid(model),
    StdResid  = rstandard(model)
  )

  list(
    model            = model,
    train_data       = train_data,
    test_data        = test_data,
    train_r2         = round(summ$r.squared, 4),
    train_adj_r2     = round(summ$adj.r.squared, 4),
    test_r2          = val_res$test_r2,
    test_rmse        = val_res$rmse,
    test_mae         = val_res$mae,
    f_stat           = round(summ$fstatistic[1], 2),
    p_value          = pf(summ$fstatistic[1], summ$fstatistic[2], summ$fstatistic[3], lower.tail = FALSE),
    coef_table       = as.data.frame(summ$coefficients),
    diagnostics      = diagnostics,
    max_train_exp    = max(train_data$experience_years, na.rm = TRUE),
    max_train_skills = max(train_data$skill_count, na.rm = TRUE)
  )
}

# -----------------------------------------------------------------------------
# run_logistic_regression()
# Logistic classification of high salary (salary >= training median)
# ZERO data leakage: threshold calculated on training split only!
# Reports out-of-sample confusion matrix, accuracy, sensitivity, specificity,
# precision, and F1 score on 20% test holdout.
# -----------------------------------------------------------------------------
run_logistic_regression <- function(df) {
  split_res  <- split_train_test(df, train_pct = 0.80, seed = 42)
  threshold  <- split_res$train_salary_median

  train_data <- split_res$train_data |>
    dplyr::filter(!is.na(skill_count), !is.na(education), !is.na(company_size_num)) |>
    dplyr::mutate(
      education        = droplevels(as.factor(as.character(education))),
      company_size_num = as.numeric(company_size_num)
    )

  test_data <- split_res$test_data |>
    dplyr::filter(!is.na(skill_count), !is.na(education), !is.na(company_size_num)) |>
    dplyr::mutate(
      education        = factor(as.character(education), levels = levels(train_data$education)),
      company_size_num = as.numeric(company_size_num)
    )

  model <- glm(
    high_salary ~ experience_years + skill_count + education + company_size_num,
    data   = train_data,
    family = binomial(link = "logit")
  )
  summ <- summary(model)

  # Training evaluation
  train_probs   <- predict(model, newdata = train_data, type = "response")
  train_metrics <- calc_classification_metrics(train_data$high_salary, train_probs, threshold = 0.5)

  # Out-of-sample Test evaluation
  test_probs   <- predict(model, newdata = test_data, type = "response")
  test_metrics <- calc_classification_metrics(test_data$high_salary, test_probs, threshold = 0.5)

  list(
    model          = model,
    threshold      = threshold,
    train_data     = train_data,
    test_data      = test_data,
    coef_table     = as.data.frame(summ$coefficients),
    train_cm       = train_metrics$cm,
    train_metrics  = train_metrics,
    test_cm        = test_metrics$cm,
    test_metrics   = test_metrics,
    aic            = round(summ$aic, 1),
    max_train_exp  = max(train_data$experience_years, na.rm = TRUE)
  )
}

# -----------------------------------------------------------------------------
# predict_salary_scenario()
# Point estimate + 95% prediction interval using Simple LR or Multiple LR
# -----------------------------------------------------------------------------
predict_salary_scenario <- function(slr_res, mlr_res, logit_res,
                                    exp_years, skill_cnt, edu_val, comp_size, loc_tier = "Tier 1") {
  exp_years <- as.numeric(exp_years)
  skill_cnt <- as.integer(skill_cnt)

  # Extrapolation check
  extrap_warn <- ""
  if (exp_years > slr_res$max_train_exp) {
    extrap_warn <- sprintf("Caution: Entered experience (%.0f yrs) exceeds maximum training data (%.0f yrs). Predictions are extrapolated.",
                           exp_years, slr_res$max_train_exp)
  }

  # 1. Simple LR estimate
  slr_newdata <- data.frame(experience_years = exp_years)
  slr_pred <- predict(slr_res$model, newdata = slr_newdata, interval = "prediction", level = 0.95)

  # Safe case-insensitive education level matching
  edu_levels <- levels(mlr_res$train_data$education)
  matched_edu <- edu_levels[tolower(edu_levels) == tolower(trimws(edu_val))]
  if (length(matched_edu) == 0) matched_edu <- edu_levels[1]

  # 2. Multiple LR estimate (if factor levels valid)
  mlr_newdata <- data.frame(
    experience_years = exp_years,
    skill_count      = skill_cnt,
    education        = factor(matched_edu, levels = edu_levels),
    company_size_num = company_size_num(comp_size),
    location_tier    = factor(loc_tier, levels = levels(mlr_res$train_data$location_tier)),
    stringsAsFactors = FALSE
  )

  mlr_pred <- tryCatch({
    predict(mlr_res$model, newdata = mlr_newdata, interval = "prediction", level = 0.95)
  }, error = function(e) {
    NULL
  })

  # 3. Logistic Regression probability
  logit_edu_levels <- levels(logit_res$train_data$education)
  matched_logit_edu <- logit_edu_levels[tolower(logit_edu_levels) == tolower(trimws(edu_val))]
  if (length(matched_logit_edu) == 0) matched_logit_edu <- logit_edu_levels[1]

  logit_newdata <- data.frame(
    experience_years = exp_years,
    skill_count      = skill_cnt,
    education        = factor(matched_logit_edu, levels = logit_edu_levels),
    company_size_num = company_size_num(comp_size),
    stringsAsFactors = FALSE
  )

  logit_prob <- tryCatch({
    p <- predict(logit_res$model, newdata = logit_newdata, type = "response")
    round(as.numeric(p) * 100, 1)
  }, error = function(e) {
    NA_real_
  })

  list(
    extrap_warn    = extrap_warn,
    slr_estimate   = as.numeric(slr_pred[1, "fit"]),
    slr_lwr        = max(0, as.numeric(slr_pred[1, "lwr"])),
    slr_upr        = as.numeric(slr_pred[1, "upr"]),
    mlr_estimate   = if (!is.null(mlr_pred)) as.numeric(mlr_pred[1, "fit"]) else NA_real_,
    mlr_lwr        = if (!is.null(mlr_pred)) max(0, as.numeric(mlr_pred[1, "lwr"])) else NA_real_,
    mlr_upr        = if (!is.null(mlr_pred)) as.numeric(mlr_pred[1, "upr"]) else NA_real_,
    high_sal_prob  = logit_prob,
    high_sal_label = ifelse(!is.na(logit_prob) && logit_prob >= 50, "High Salary", "Standard / Mid Salary")
  )
}
