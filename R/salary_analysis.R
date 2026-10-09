# =============================================================================
# salary_analysis.R
# CareerLens — ITA04: Statistics with R Programming
# -----------------------------------------------------------------------------
# Functions:
#   calculate_salary_summary() - full descriptive stats for a numeric vector
#   salary_by_role()           - grouped stats per job_title
#   salary_by_location()       - grouped stats per location
#   salary_by_experience()     - binned stats per experience level
# =============================================================================

source("R/helper_functions.R")

# -----------------------------------------------------------------------------
# calculate_salary_summary()
# Returns a named list of descriptive statistics for salary_inr
# -----------------------------------------------------------------------------
calculate_salary_summary <- function(df) {
  x <- df$salary_inr[!is.na(df$salary_inr)]
  if (length(x) == 0) return(list())

  list(
    n          = length(x),
    mean       = mean(x),
    median     = median(x),
    mode       = stat_mode(round(x / 10000) * 10000),  # modal bucket
    min        = min(x),
    max        = max(x),
    range      = max(x) - min(x),
    variance   = var(x),
    sd         = sd(x),
    q1         = quantile(x, 0.25),
    q3         = quantile(x, 0.75),
    iqr        = IQR(x),
    p10        = quantile(x, 0.10),
    p90        = quantile(x, 0.90),
    cv_pct     = round(sd(x) / mean(x) * 100, 1)  # coefficient of variation
  )
}

# -----------------------------------------------------------------------------
# salary_by_role()
# Mean, median, SD per job title — sorted descending by mean
# -----------------------------------------------------------------------------
salary_by_role <- function(df, top_n = 20) {
  df |>
    dplyr::filter(!is.na(salary_inr)) |>
    dplyr::group_by(job_title) |>
    dplyr::summarise(
      n          = dplyr::n(),
      mean_salary = mean(salary_inr),
      median_salary = median(salary_inr),
      sd_salary   = sd(salary_inr),
      min_salary  = min(salary_inr),
      max_salary  = max(salary_inr),
      .groups     = "drop"
    ) |>
    dplyr::arrange(dplyr::desc(mean_salary)) |>
    dplyr::slice_head(n=top_n)
}

# -----------------------------------------------------------------------------
# salary_by_location()
# Mean, median per location — sorted descending by mean
# -----------------------------------------------------------------------------
salary_by_location <- function(df, top_n = 20) {
  df |>
    dplyr::filter(!is.na(salary_inr), !is.na(location)) |>
    dplyr::group_by(location) |>
    dplyr::summarise(
      n             = dplyr::n(),
      mean_salary   = mean(salary_inr),
      median_salary = median(salary_inr),
      sd_salary     = sd(salary_inr),
      .groups       = "drop"
    ) |>
    dplyr::arrange(dplyr::desc(mean_salary)) |>
    dplyr::slice_head(n=top_n)
}

# -----------------------------------------------------------------------------
# salary_by_experience()
# Mean salary per experience bin
# -----------------------------------------------------------------------------
salary_by_experience <- function(df) {
  df |>
    dplyr::filter(!is.na(salary_inr), !is.na(experience_bin)) |>
    dplyr::group_by(experience_bin) |>
    dplyr::summarise(
      n             = dplyr::n(),
      mean_salary   = mean(salary_inr),
      median_salary = median(salary_inr),
      .groups       = "drop"
    ) |>
    dplyr::arrange(experience_bin)
}
