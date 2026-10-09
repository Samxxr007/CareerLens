# =============================================================================
# data_cleaning.R
# CareerLens — ITA04: Statistics with R Programming
# -----------------------------------------------------------------------------
# Functions:
#   clean_text()          - normalize text fields
#   load_and_clean()      - full preprocessing pipeline
#   data_quality_report() - returns QA summary as a list
# =============================================================================

source("R/helper_functions.R")

# -----------------------------------------------------------------------------
# clean_text()
# Trim whitespace, normalize to Title Case, collapse internal spaces
# -----------------------------------------------------------------------------
clean_text <- function(x) {
  x <- as.character(x)
  x <- trimws(x)                          # remove leading/trailing spaces
  x <- gsub("\\s+", " ", x)              # collapse multiple spaces
  x <- tools::toTitleCase(tolower(x))    # normalize case
  x[x == "" | x == "Na" | x == "N A"] <- NA
  x
}

# -----------------------------------------------------------------------------
# load_and_clean()
# Main preprocessing pipeline. Reads raw CSV, cleans, and writes clean CSV.
# Returns the cleaned data frame.
# -----------------------------------------------------------------------------
load_and_clean <- function(raw_path    = "data/job_market.csv",
                            clean_path  = "data/job_market_clean.csv",
                            force_regen = FALSE) {

  # Return cached clean data if already generated
  if (!force_regen && file.exists(clean_path)) {
    message("Loading cached clean dataset from: ", clean_path)
    df <- readr::read_csv(clean_path, show_col_types=FALSE)
    df$experience_bin  <- experience_bin(df$experience_years)
    df$company_size_num <- company_size_num(df$company_size)
    df$location_tier   <- location_tier(df$location)
    return(df)
  }

  # ------ Step 1: Read raw data ------
  message("Reading raw dataset: ", raw_path)
  df_raw <- readr::read_csv(raw_path, show_col_types=FALSE)
  raw_rows <- nrow(df_raw)
  message("Raw rows: ", raw_rows, " | Columns: ", ncol(df_raw))

  df <- df_raw

  # ------ Step 2: Check structure ------
  # Ensure key columns exist
  required_cols <- c("job_id","job_title","company","location","salary_inr",
                     "experience_years","skills","employment_type","education")
  missing_cols <- setdiff(required_cols, names(df))
  if (length(missing_cols) > 0) {
    stop("Missing required columns: ", paste(missing_cols, collapse=", "))
  }

  # ------ Step 3: Detect and remove duplicates ------
  n_before <- nrow(df)
  # Duplicates on key business columns (not job_id which may differ for _DUP rows)
  dup_cols  <- c("job_title","company","location","experience_years","skills")
  dupe_mask <- duplicated(df[, dup_cols])
  n_dupes   <- sum(dupe_mask)
  df <- df[!dupe_mask, ]
  message("Duplicates removed: ", n_dupes, " | Rows after dedup: ", nrow(df))

  # ------ Step 4: Text normalization ------
  df$job_title    <- clean_text(df$job_title)
  df$company      <- clean_text(df$company)
  df$location     <- clean_text(df$location)
  df$state        <- clean_text(df$state)
  df$industry     <- clean_text(df$industry)
  df$employment_type <- clean_text(df$employment_type)
  df$education    <- clean_text(df$education)
  df$remote_type  <- clean_text(df$remote_type)
  df$company_size <- clean_text(df$company_size)

  # ------ Step 5: Handle missing values ------

  # salary_inr: impute missing with median of same job_title group
  df <- df |>
    dplyr::group_by(job_title) |>
    dplyr::mutate(
      salary_inr = dplyr::if_else(
        is.na(salary_inr),
        median(salary_inr, na.rm=TRUE),
        as.numeric(salary_inr)
      )
    ) |>
    dplyr::ungroup()

  # Remaining NA salary_inr (titles with all-NA) → global median
  global_salary_median <- median(df$salary_inr, na.rm=TRUE)
  df$salary_inr[is.na(df$salary_inr)] <- global_salary_median

  # education: impute with mode
  edu_mode <- stat_mode(df$education)
  df$education[is.na(df$education)] <- edu_mode

  # company_size: impute with mode
  size_mode <- stat_mode(df$company_size)
  df$company_size[is.na(df$company_size)] <- size_mode

  # skills: impute with empty string (will count as 0 skills)
  df$skills[is.na(df$skills)] <- ""

  # location: impute with mode
  loc_mode <- stat_mode(df$location)
  df$location[is.na(df$location)] <- loc_mode

  # ------ Step 6: Type conversion ------
  df$experience_years <- as.integer(df$experience_years)
  df$salary_inr       <- as.numeric(df$salary_inr)
  df$salary_min       <- as.numeric(df$salary_min)
  df$salary_max       <- as.numeric(df$salary_max)
  df$posted_date      <- as.Date(df$posted_date)
  df$skill_count      <- as.integer(df$skill_count)

  # Recompute skill_count after imputation
  df$skill_count <- sapply(strsplit(df$skills, ";"), function(s) sum(nzchar(trimws(s))))

  # ------ Step 7: Factor columns ------
  df$job_title       <- as.factor(df$job_title)
  df$industry        <- as.factor(df$industry)
  df$employment_type <- as.factor(df$employment_type)
  df$education       <- as.factor(df$education)
  df$remote_type     <- as.factor(df$remote_type)
  df$company_size    <- as.factor(df$company_size)

  # ------ Step 8: Derived columns ------
  df$experience_bin   <- experience_bin(df$experience_years)
  df$company_size_num <- company_size_num(df$company_size)
  df$location_tier    <- location_tier(df$location)

  # high_salary flag — 1 if salary_inr >= median (used for logistic regression)
  salary_median_threshold <- median(df$salary_inr, na.rm=TRUE)
  df$high_salary <- as.integer(df$salary_inr >= salary_median_threshold)

  # ------ Step 9: Outlier detection (flag only, do not remove) ------
  q1  <- quantile(df$salary_inr, 0.25, na.rm=TRUE)
  q3  <- quantile(df$salary_inr, 0.75, na.rm=TRUE)
  iqr <- q3 - q1
  df$salary_outlier <- as.integer(
    df$salary_inr < (q1 - 3 * iqr) | df$salary_inr > (q3 + 3 * iqr)
  )
  n_outliers <- sum(df$salary_outlier, na.rm=TRUE)
  message("Salary outliers flagged (not removed): ", n_outliers)

  # ------ Step 10: Validate numeric fields ------
  df <- df[!is.na(df$experience_years) & df$experience_years >= 0, ]
  df <- df[df$salary_inr > 0, ]

  clean_rows <- nrow(df)
  message("Clean rows: ", clean_rows)

  # ------ Step 11: Save clean CSV ------
  readr::write_csv(df, clean_path)
  message("Clean dataset saved: ", clean_path)

  df
}

# -----------------------------------------------------------------------------
# data_quality_report()
# Returns a named list summarising data quality for display in the app
# -----------------------------------------------------------------------------
data_quality_report <- function(raw_path  = "data/job_market.csv",
                                clean_path = "data/job_market_clean.csv") {

  df_raw   <- readr::read_csv(raw_path,   show_col_types=FALSE)
  df_clean <- readr::read_csv(clean_path, show_col_types=FALSE)

  # Per-column missing in raw
  na_counts <- sapply(df_raw, function(x) sum(is.na(x)))

  # Duplicate rows in raw (on key cols)
  dup_cols  <- c("job_title","company","location","experience_years","skills")
  n_dupes   <- sum(duplicated(df_raw[, intersect(dup_cols, names(df_raw))]))

  list(
    raw_rows    = nrow(df_raw),
    raw_cols    = ncol(df_raw),
    n_dupes     = n_dupes,
    na_counts   = na_counts,
    total_na    = sum(na_counts),
    clean_rows  = nrow(df_clean),
    clean_cols  = ncol(df_clean)
  )
}
