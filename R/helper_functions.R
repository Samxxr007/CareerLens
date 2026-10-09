# =============================================================================
# helper_functions.R
# CareerLens — ITA04: Statistics with R Programming
# Shared utility functions used across modules
# =============================================================================

# Null-coalescing operator
`%||%` <- function(a, b) if (!is.null(a) && length(a) > 0) a else b

# -----------------------------------------------------------------------------
# format_inr()
# Format a numeric salary (in INR) as a readable string: ₹X.XX L or ₹X.XX Cr
# -----------------------------------------------------------------------------
format_inr <- function(x, digits = 2) {
  x <- as.numeric(x)
  ifelse(
    is.na(x), "N/A",
    ifelse(
      x >= 1e7,
      paste0("\u20B9", round(x / 1e7, digits), " Cr"),
      paste0("\u20B9", round(x / 1e5, digits), " L")
    )
  )
}

# -----------------------------------------------------------------------------
# experience_bin()
# Bin experience_years into labeled categories (factor)
# -----------------------------------------------------------------------------
experience_bin <- function(yrs) {
  cut(
    as.numeric(yrs),
    breaks = c(-Inf, 1, 3, 6, 10, Inf),
    labels = c("Fresher (0-1)", "Junior (2-3)", "Mid (4-6)", "Senior (7-10)", "Lead (10+)"),
    right  = TRUE
  )
}

# -----------------------------------------------------------------------------
# company_size_num()
# Convert categorical company size to ordinal numeric for regression
# -----------------------------------------------------------------------------
company_size_num <- function(size) {
  mapping <- c(Small=1L, Medium=2L, Large=3L, Enterprise=4L)
  as.integer(mapping[as.character(size)])
}

# -----------------------------------------------------------------------------
# location_tier()
# Classify locations into Tier 1 / Tier 2 / International
# -----------------------------------------------------------------------------
location_tier <- function(loc) {
  tier1_india <- c("Bengaluru","Hyderabad","Chennai","Pune","Mumbai",
                   "Delhi","Gurugram","Noida")
  intl        <- c("London","Toronto","Singapore","Dubai","New York","Berlin")
  dplyr::case_when(
    loc %in% tier1_india ~ "Tier 1",
    loc %in% intl        ~ "International",
    TRUE                 ~ "Tier 2"
  )
}

# -----------------------------------------------------------------------------
# stat_label()
# Generate a strength label for a Pearson correlation coefficient
# -----------------------------------------------------------------------------
stat_label <- function(r) {
  abs_r <- abs(r)
  dir   <- ifelse(r >= 0, "positive", "negative")
  strength <- dplyr::case_when(
    abs_r >= 0.70 ~ "strong",
    abs_r >= 0.40 ~ "moderate",
    abs_r >= 0.20 ~ "weak",
    TRUE          ~ "negligible"
  )
  paste(strength, dir)
}

# -----------------------------------------------------------------------------
# safe_mean() / safe_median() — NA-safe wrappers
# -----------------------------------------------------------------------------
safe_mean   <- function(x, ...) mean(x, na.rm=TRUE, ...)
safe_median <- function(x, ...) median(x, na.rm=TRUE, ...)
safe_sd     <- function(x, ...) sd(x, na.rm=TRUE, ...)
safe_var    <- function(x, ...) var(x, na.rm=TRUE, ...)

# Statistical mode (most frequent value)
stat_mode <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) == 0) return(NA)
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}
