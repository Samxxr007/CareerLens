# =============================================================================
# model_validation.R
# CareerLens — ITA04: Statistics with R Programming
# -----------------------------------------------------------------------------
# Reusable Statistical Validation & Metric Evaluation Utilities:
#   1. calc_regression_metrics()     - MAE, RMSE, Test R-squared
#   2. calc_classification_metrics() - CM, Accuracy, Sensitivity, Specificity,
#                                      Precision, F1 Score
#   3. split_train_test()            - Deterministic 80/20 partition with
#                                      leak-free training-only statistics
# =============================================================================

# -----------------------------------------------------------------------------
# calc_regression_metrics()
# Computes Mean Absolute Error (MAE), Root Mean Squared Error (RMSE), and Test R2
# -----------------------------------------------------------------------------
calc_regression_metrics <- function(actual, predicted) {
  valid_idx <- !is.na(actual) & !is.na(predicted)
  actual    <- actual[valid_idx]
  predicted <- predicted[valid_idx]

  n <- length(actual)
  if (n == 0) {
    return(list(mae = NA_real_, rmse = NA_real_, test_r2 = NA_real_))
  }

  mae  <- mean(abs(actual - predicted))
  rmse <- sqrt(mean((actual - predicted)^2))

  sse <- sum((actual - predicted)^2)
  sst <- sum((actual - mean(actual))^2)
  test_r2 <- if (sst > 0) max(0, 1 - (sse / sst)) else 0

  list(
    n       = n,
    mae     = round(mae),
    rmse    = round(rmse),
    test_r2 = round(test_r2, 4)
  )
}

# -----------------------------------------------------------------------------
# calc_classification_metrics()
# Derives 2x2 confusion matrix and diagnostic performance metrics
# (Accuracy, Sensitivity/Recall, Specificity, Precision, F1 Score)
# -----------------------------------------------------------------------------
calc_classification_metrics <- function(actual, predicted_prob, threshold = 0.5) {
  valid_idx <- !is.na(actual) & !is.na(predicted_prob)
  actual    <- actual[valid_idx]
  prob      <- predicted_prob[valid_idx]

  if (length(actual) == 0) {
    return(list(
      cm          = matrix(0, 2, 2),
      accuracy    = NA_real_,
      sensitivity = NA_real_,
      specificity = NA_real_,
      precision   = NA_real_,
      f1_score    = NA_real_
    ))
  }

  pred_class <- as.integer(prob >= threshold)
  
  # Ensure 2x2 factor table
  actual_f <- factor(actual, levels = c(0, 1))
  pred_f   <- factor(pred_class, levels = c(0, 1))
  cm <- table(Actual = actual_f, Predicted = pred_f)

  tn <- as.numeric(cm["0", "0"])
  fp <- as.numeric(cm["0", "1"])
  fn <- as.numeric(cm["1", "0"])
  tp <- as.numeric(cm["1", "1"])
  total <- sum(cm)

  accuracy    <- if (total > 0) (tp + tn) / total else NA_real_
  sensitivity <- if ((tp + fn) > 0) tp / (tp + fn) else NA_real_  # Recall
  specificity <- if ((tn + fp) > 0) tn / (tn + fp) else NA_real_
  precision   <- if ((tp + fp) > 0) tp / (tp + fp) else NA_real_
  
  f1_score <- if (!is.na(precision) && !is.na(sensitivity) && (precision + sensitivity) > 0) {
    2 * (precision * sensitivity) / (precision + sensitivity)
  } else {
    NA_real_
  }

  list(
    cm          = cm,
    accuracy    = round(accuracy * 100, 1),
    sensitivity = round(sensitivity * 100, 1),
    specificity = round(specificity * 100, 1),
    precision   = round(precision * 100, 1),
    f1_score    = round(f1_score * 100, 1)
  )
}

# -----------------------------------------------------------------------------
# split_train_test()
# Deterministic train/test partition (default 80/20, seed = 42)
# Excludes NA salaries and applies training-only median calculation
# to guarantee ZERO data leakage.
# -----------------------------------------------------------------------------
split_train_test <- function(df, train_pct = 0.80, seed = 42) {
  set.seed(seed)

  # Filter out missing salaries and extreme outliers for model stability
  df_valid <- df |>
    dplyr::filter(!is.na(salary_inr), salary_inr > 0)

  if ("salary_outlier" %in% names(df_valid)) {
    df_valid <- df_valid |> dplyr::filter(salary_outlier == 0)
  }

  n <- nrow(df_valid)
  train_idx <- sample(seq_len(n), size = round(train_pct * n))
  train_data <- df_valid[train_idx, ]
  test_data  <- df_valid[-train_idx, ]

  # Training-only threshold (LEAK-FREE)
  train_salary_median <- median(train_data$salary_inr, na.rm = TRUE)

  train_data$high_salary <- as.integer(train_data$salary_inr >= train_salary_median)
  test_data$high_salary  <- as.integer(test_data$salary_inr >= train_salary_median)

  list(
    train_data          = train_data,
    test_data           = test_data,
    train_salary_median = train_salary_median,
    n_train             = nrow(train_data),
    n_test              = nrow(test_data)
  )
}
