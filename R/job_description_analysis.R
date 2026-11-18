# =============================================================================
# job_description_analysis.R
# CareerLens — ITA04: Statistics with R Programming
# -----------------------------------------------------------------------------
# Offline, Dictionary-Based Job Description Analyzer:
#   1. build_skill_dictionary()   - Compiles unique skills & market demand
#   2. extract_skills_from_text() - Boundary-aware keyword extraction with special chars
#   3. analyze_job_description()  - Gap analysis against candidate profile & market demand
# =============================================================================

source("R/skill_analysis.R")

# -----------------------------------------------------------------------------
# build_skill_dictionary()
# Compiles all recognized skills in dataset with categories and market demand
# -----------------------------------------------------------------------------
build_skill_dictionary <- function(df) {
  demand_tbl <- calculate_skill_demand(df)
  all_skills <- unique(trimws(demand_tbl$skill))
  all_skills <- all_skills[nzchar(all_skills)]

  # Sort skills by descending character length to match longer multi-word phrases first
  # e.g., "Spring Boot" before "Spring", "Node.js" before "Node"
  all_skills <- all_skills[order(nchar(all_skills), decreasing = TRUE)]

  list(
    skills_vec = all_skills,
    demand_tbl = demand_tbl
  )
}

# -----------------------------------------------------------------------------
# extract_skills_from_text()
# Performs case-insensitive, boundary-aware matching of dictionary skills
# Handles special terms: C++, C#, .NET, Node.js, CI/CD, REST API, scikit-learn, Power BI, R
# -----------------------------------------------------------------------------
extract_skills_from_text <- function(text, skill_dict) {
  if (is.null(text) || !nzchar(trimws(text))) {
    return(character(0))
  }

  skills_pool  <- skill_dict$skills_vec
  found_skills <- character(0)

  # Pad text with spaces for boundary matching
  padded_text <- paste0(" ", text, " ")

  for (sk in skills_pool) {
    if (sk == "R") {
      # Standalone single-letter "R": requires non-alphanumeric boundary on both sides
      # Avoids matching within "Research", "Requirements", etc.
      pattern <- "(?<=[\\s,;./()\\[\\]{}:<>]|^)R(?=[\\s,;./()\\[\\]{}:<>]|$)"
      if (grepl(pattern, padded_text, perl = TRUE)) {
        found_skills <- c(found_skills, sk)
      }
    } else {
      # Escape regex special characters
      sk_escaped <- gsub("([.\\^$*+?()[{\\\\|])", "\\\\\\1", sk)
      pattern <- paste0("(?i)(?<=[^a-zA-Z0-9+#]|^)", sk_escaped, "(?=[^a-zA-Z0-9+#]|$)")
      if (grepl(pattern, padded_text, perl = TRUE)) {
        found_skills <- c(found_skills, sk)
      }
    }
  }

  unique(found_skills)
}

# -----------------------------------------------------------------------------
# analyze_job_description()
# Compares skills extracted from pasted job description against candidate skills
# Categorizes missing skills using the Priority Index heuristic
# -----------------------------------------------------------------------------
analyze_job_description <- function(text, candidate_skills, target_role, df, skill_dict) {
  extracted <- extract_skills_from_text(text, skill_dict)
  candidate_skills <- if (!is.null(candidate_skills)) trimws(as.character(candidate_skills)) else character(0)

  if (length(extracted) == 0) {
    return(list(
      has_skills       = FALSE,
      extracted_count  = 0,
      matched_skills   = character(0),
      missing_skills   = character(0),
      breakdown_tbl    = data.frame(),
      recommendations  = character(0),
      disclaimer       = "No recognized skills from the dataset dictionary were detected in the text."
    ))
  }

  matched <- intersect(extracted, candidate_skills)
  missing <- setdiff(extracted, candidate_skills)

  # Join market demand & role demand
  market_tbl <- skill_dict$demand_tbl
  role_tbl   <- if (!is.null(target_role) && nzchar(target_role)) {
    role_skill_demand(df, target_role, top_n = NULL)
  } else {
    data.frame()
  }

  breakdown_list <- lapply(extracted, function(sk) {
    cat_val <- get_skill_category(sk)

    mkt_match  <- market_tbl |> dplyr::filter(skill == sk)
    mkt_demand <- if (nrow(mkt_match) > 0) mkt_match$demand_pct[1] else 0.0

    role_demand <- if (nrow(role_tbl) > 0) {
      r_match <- role_tbl |> dplyr::filter(skill == sk)
      if (nrow(r_match) > 0) r_match$demand_pct[1] else 0.0
    } else {
      mkt_demand
    }

    # Priority Index calculation for missing skills
    p_index <- round(0.70 * role_demand + 0.30 * mkt_demand, 1)
    status  <- ifelse(sk %in% candidate_skills, "Matched", "Missing")
    p_cat   <- if (status == "Matched") {
      "Satisfied"
    } else if (p_index >= 35.0) {
      "HIGH PRIORITY"
    } else if (p_index >= 15.0) {
      "MEDIUM PRIORITY"
    } else {
      "ADDITIONAL SKILL"
    }

    data.frame(
      Skill             = sk,
      Category          = cat_val,
      Status            = status,
      `Role Demand %`   = role_demand,
      `Market Demand %` = mkt_demand,
      `Priority Index`  = p_index,
      `Priority Level`  = p_cat,
      check.names       = FALSE,
      stringsAsFactors  = FALSE
    )
  })

  breakdown_tbl <- do.call(rbind, breakdown_list)

  # Sort: Missing skills first, ordered by Priority Index descending
  breakdown_tbl <- breakdown_tbl |>
    dplyr::arrange(
      dplyr::desc(Status == "Missing"),
      dplyr::desc(`Priority Index`)
    )

  missing_recs <- breakdown_tbl |>
    dplyr::filter(Status == "Missing") |>
    head(5)

  list(
    has_skills       = TRUE,
    extracted_count  = length(extracted),
    matched_skills   = matched,
    missing_skills   = missing,
    breakdown_tbl    = breakdown_tbl,
    recommendations  = missing_recs$Skill,
    disclaimer       = "Dictionary-based skill recognition based on CareerLens dataset vocabulary. Does not guarantee complete semantic qualification parsing."
  )
}
