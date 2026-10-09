# =============================================================================
# regression_analysis.R
# CareerLens — ITA04: Statistics with R Programming
# -----------------------------------------------------------------------------
# Functions:
#   run_simple_regression()      - lm(salary_inr ~ experience_years)
#   run_multiple_regression()    - lm with multiple predictors
#   run_logistic_regression()    - glm(high_salary ~ ..., family=binomial)
#   predict_salary()             - point estimate from lm model
#   predict_high_salary_prob()   - probability estimate from glm model
#   confusion_matrix_summary()   - accuracy, sensitivity, specificity
# =============================================================================

source("R/helper_functions.R")

# -----------------------------------------------------------------------------
# run_simple_regression()
# Simple linear regression: salary_inr ~ experience_years
# Returns a list with model, summary, and equation string
# -----------------------------------------------------------------------------
run_simple_regression <- function(df) {
  df_model <- df |>
    dplyr::filter(!is.na(salary_inr), !is.na(experience_years)) |>
    dplyr::filter(salary_outlier == 0)   # exclude extreme outliers for cleaner model

  model   <- lm(salary_inr ~ experience_years, data=df_model)
  summ    <- summary(model)

  intercept <- coef(model)[["(Intercept)"]]
  slope     <- coef(model)[["experience_years"]]
  r_sq      <- summ$r.squared
  adj_r_sq  <- summ$adj.r.squared
  p_val     <- summ$coefficients["experience_years", "Pr(>|t|)"]
  f_stat    <- summ$fstatistic[1]

  equation <- sprintf(
    "salary_inr = %s + %s \u00D7 experience_years",
    format(round(intercept), big.mark=","),
    format(round(slope), big.mark=",")
  )

  list(
    model      = model,
    data       = df_model,
    intercept  = intercept,
    slope      = slope,
    r_squared  = r_sq,
    adj_r_sq   = adj_r_sq,
    p_value    = p_val,
    f_stat     = f_stat,
    equation   = equation,
    coef_table = as.data.frame(summ$coefficients)
  )
}

# -----------------------------------------------------------------------------
# run_multiple_regression()
# Multiple linear regression: salary_inr ~ experience + skill_count +
#                              education + company_size_num + location_tier
# -----------------------------------------------------------------------------
run_multiple_regression <- function(df) {
  df_model <- df |>
    dplyr::filter(
      !is.na(salary_inr), !is.na(experience_years),
      !is.na(skill_count), !is.na(education),
      !is.na(company_size_num), !is.na(location_tier),
      salary_outlier == 0
    ) |>
    dplyr::mutate(
      education     = droplevels(as.factor(as.character(education))),
      location_tier = as.factor(location_tier)
    )

  model  <- lm(
    salary_inr ~ experience_years + skill_count + education + company_size_num + location_tier,
    data = df_model
  )
  summ   <- summary(model)

  list(
    model      = model,
    data       = df_model,
    r_squared  = summ$r.squared,
    adj_r_sq   = summ$adj.r.squared,
    f_stat     = summ$fstatistic[1],
    p_value    = pf(summ$fstatistic[1], summ$fstatistic[2], summ$fstatistic[3], lower.tail=FALSE),
    coef_table = as.data.frame(summ$coefficients)
  )
}

# -----------------------------------------------------------------------------
# run_logistic_regression()
# Logistic regression: high_salary ~ experience + skill_count +
#                      education + company_size_num
# high_salary = 1 if salary_inr >= median(salary_inr)
# -----------------------------------------------------------------------------
run_logistic_regression <- function(df) {
  threshold <- median(df$salary_inr, na.rm=TRUE)

  df_model <- df |>
    dplyr::filter(
      !is.na(salary_inr), !is.na(experience_years),
      !is.na(skill_count), !is.na(education),
      !is.na(company_size_num)
    ) |>
    dplyr::mutate(
      high_salary   = as.integer(salary_inr >= threshold),
      education     = droplevels(as.factor(as.character(education))),
      company_size_num = as.numeric(company_size_num)
    )

  model <- glm(
    high_salary ~ experience_years + skill_count + education + company_size_num,
    data   = df_model,
    family = binomial(link="logit")
  )
  summ <- summary(model)

  # Predictions on training set
  fitted_probs  <- predict(model, type="response")
  fitted_class  <- as.integer(fitted_probs >= 0.5)
  cm <- table(Actual=df_model$high_salary, Predicted=fitted_class)

  list(
    model      = model,
    data       = df_model,
    threshold  = threshold,
    coef_table = as.data.frame(summ$coefficients),
    cm         = cm,
    cm_summary = confusion_matrix_summary(cm),
    aic        = summ$aic
  )
}

# -----------------------------------------------------------------------------
# confusion_matrix_summary()
# Derives accuracy, sensitivity, specificity from a 2x2 confusion matrix
# -----------------------------------------------------------------------------
confusion_matrix_summary <- function(cm) {
  # cm is a table with rows=Actual, cols=Predicted
  if (!all(dim(cm) == c(2,2))) {
    return(list(accuracy=NA, sensitivity=NA, specificity=NA))
  }
  tn <- cm[1,1]; fp <- cm[1,2]
  fn <- cm[2,1]; tp <- cm[2,2]
  list(
    accuracy    = round((tp + tn) / sum(cm) * 100, 1),
    sensitivity = round(tp / (tp + fn) * 100, 1),
    specificity = round(tn / (tn + fp) * 100, 1)
  )
}

# -----------------------------------------------------------------------------
# predict_salary()
# Returns predicted salary_inr from the simple lm model for given experience
# -----------------------------------------------------------------------------
predict_salary <- function(simple_model_result, experience_years) {
  newdata <- data.frame(experience_years=as.numeric(experience_years))
  pred    <- predict(simple_model_result$model, newdata=newdata, interval="predict")
  list(
    estimate = pred[,"fit"],
    lower    = pred[,"lwr"],
    upper    = pred[,"upr"]
  )
}

# -----------------------------------------------------------------------------
# predict_high_salary_prob()
# Returns probability of high salary from glm model for user inputs
# -----------------------------------------------------------------------------
predict_high_salary_prob <- function(logit_result, experience_years,
                                     skill_count, education, company_size) {
  size_num <- company_size_num(company_size)

  newdata <- data.frame(
    experience_years  = as.numeric(experience_years),
    skill_count       = as.integer(skill_count),
    education         = factor(education,
                               levels=levels(logit_result$data$education)),
    company_size_num  = as.numeric(size_num),
    stringsAsFactors  = FALSE
  )

  # Predict with error handling
  tryCatch({
    prob <- predict(logit_result$model, newdata=newdata, type="response")
    list(
      probability  = round(as.numeric(prob) * 100, 1),
      predicted    = ifelse(prob >= 0.5, "High Salary", "Low / Mid Salary"),
      threshold    = logit_result$threshold
    )
  }, error=function(e) {
    list(probability=NA, predicted="Prediction unavailable", threshold=logit_result$threshold)
  })
}
