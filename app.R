# =============================================================================
# app.R
# CareerLens — Interactive Job Market & Career Decision-Support Application
# Course: ITA04 — Statistics with R Programming (Capstone Project)
# -----------------------------------------------------------------------------
# Usage:
#   shiny::runApp()  OR  open in RStudio and click 'Run App'
# =============================================================================

library(shiny)
library(bslib)
library(dplyr)
library(tidyr)
library(ggplot2)
library(plotly)
library(readr)
library(stringr)
library(DT)
library(scales)
library(corrplot)

# Source analytical modules
source("R/helper_functions.R")
source("R/data_cleaning.R")
source("R/skill_analysis.R")
source("R/salary_analysis.R")
source("R/model_validation.R")
source("R/regression_analysis.R")
source("R/career_fit.R")
source("R/recommendation_engine.R")
source("R/job_description_analysis.R")

# -----------------------------------------------------------------------------
# 1. STARTUP INITIALIZATION & CACHING
# -----------------------------------------------------------------------------
message("CareerLens: Initializing data and models...")

df_clean <- load_and_clean()
qr       <- data_quality_report()

# Pre-compile skill dictionary and unique lists
skill_dict       <- build_skill_dictionary(df_clean)
skill_demand_all <- skill_dict$demand_tbl
all_skills       <- skill_dict$skills_vec

# Pre-train regression models with 80/20 train/test evaluation (seed = 42)
slr_res   <- run_simple_regression(df_clean)
mlr_res   <- run_multiple_regression(df_clean)
logit_res <- run_logistic_regression(df_clean)

message("CareerLens ready. Clean dataset: ", nrow(df_clean), " records.")

# -----------------------------------------------------------------------------
# 2. THEME & COLOUR PALETTE (Option 1: Classic Academic Navy)
# System font stack used for 100% offline compliance (no external Google Fonts)
# -----------------------------------------------------------------------------
app_theme <- bs_theme(
  version = 5,
  primary = "#1E6091",
  bg      = "#f8f9fa",
  fg      = "#1a1a1a"
)

BLUE  <- "#1E6091"
GREY  <- "#6c757d"
GREEN <- "#198754"
RED   <- "#dc3545"
AMBER <- "#d97706"

# Global dropdown choices
choices_location   <- c("All", sort(unique(as.character(df_clean$location))))
choices_title      <- c("All", sort(levels(df_clean$job_title)))
choices_roles_only <- sort(levels(df_clean$job_title))
choices_exp        <- c("All", "Fresher (0-1)", "Junior (2-3)", "Mid (4-6)", "Senior (7-10)", "Lead (10+)")
choices_industry   <- c("All", sort(levels(df_clean$industry)))
choices_emptype    <- c("All", sort(levels(df_clean$employment_type)))
choices_remote     <- c("All", sort(levels(df_clean$remote_type)))
choices_education  <- levels(df_clean$education)
choices_company_size <- c("Small", "Medium", "Large", "Enterprise")

apply_filters <- function(df, location="All", title="All", exp_level="All",
                           industry="All", emp_type="All", remote="All") {
  if (location  != "All") df <- df[df$location == location, ]
  if (title     != "All") df <- df[as.character(df$job_title) == title, ]
  if (exp_level != "All") df <- df[as.character(df$experience_bin) == exp_level, ]
  if (industry  != "All") df <- df[as.character(df$industry) == industry, ]
  if (emp_type  != "All") df <- df[as.character(df$employment_type) == emp_type, ]
  if (remote    != "All") df <- df[as.character(df$remote_type) == remote, ]
  df
}

no_data_plotly <- function(msg = "No records match the selected filters.") {
  plotly_empty() |> layout(title = list(text = msg, font = list(color = GREY, size = 12)))
}

# =============================================================================
# 3. USER INTERFACE (7 CORE SECTIONS)
# =============================================================================
ui <- page_navbar(
  title = tags$span(
    tags$strong("CareerLens"),
    tags$span(" | Interactive Career Decision-Support", style = "font-weight:300; color:#cde2f5; font-size:0.9em;")
  ),
  theme    = app_theme,
  id       = "main_nav",
  selected = "Home",
  header   = tags$head(
    tags$link(rel = "stylesheet", href = "styles.css")
  ),

  # ---------------------------------------------------------------------------
  # TAB 1: HOME (Academic Intro, Workflow & Synthetic Data Disclosure)
  # ---------------------------------------------------------------------------
  nav_panel("Home",
    div(style = "max-width: 1050px; margin: 0 auto; padding: 1.5rem 0.5rem;",
      div(class = "card p-4 shadow-sm mb-4 border-0", style = "background: linear-gradient(135deg, #ffffff 0%, #f1f5f9 100%); border-left: 5px solid #1E6091 !important;",
        tags$span(class = "badge bg-primary mb-2", style = "width: fit-content;", "ITA04 — Statistics with R Programming Capstone"),
        tags$h2("CareerLens: Job Market Analysis & Decision-Support System", style = "color: #1E6091; font-weight: 700;"),
        tags$p(class = "lead text-muted",
          "An explainable, evidence-backed analytical tool that matches candidate profiles against observed job requirements, quantifies skill gaps, simulates career interventions, and provides statistical salary predictions using R."
        ),
        div(class = "mt-3",
          actionButton("home_to_profile_btn", "Build My Career Profile →", class = "btn btn-primary btn-lg px-4 shadow-sm")
        )
      ),

      fluidRow(
        column(4,
          div(class = "card h-100 p-3",
            tags$h5("1. Profile & Alignment", style = "color: #1E6091; font-weight: 600;"),
            tags$p(class = "text-muted small",
              "Enter your skills, experience, and target role. The Career Fit Engine calculates two distinct metrics: Distinct Skill Coverage (%) and Posting-Level Overlap (>=80%)."
            )
          )
        ),
        column(4,
          div(class = "card h-100 p-3",
            tags$h5("2. Gaps & What-If Lab", style = "color: #1E6091; font-weight: 600;"),
            tags$p(class = "text-muted small",
              "Prioritize missing skills using the explainable Priority Index (0.70 Role + 0.30 Market Demand) and immediately test proposed learning interventions in the What-If Simulator."
            )
          )
        ),
        column(4,
          div(class = "card h-100 p-3",
            tags$h5("3. Statistical Prediction", style = "color: #1E6091; font-weight: 600;"),
            tags$p(class = "text-muted small",
              "Evaluate Simple, Multiple, and Logistic regressions trained on 80% holdout splits, inspect residual diagnostics, and compute predictions with 95% intervals."
            )
          )
        )
      ),

      div(class = "academic-disclaimer mt-4",
        tags$strong("Academic Dataset Disclosure: "),
        "This project utilizes a synthetically generated dataset of 6,030 job market postings (6,000 clean records) generated strictly in R with realistic statistical properties (positive skewness, variance heterogeneity, missing values, and salary outliers). All employer names represent 52 fictional tech enterprises to avoid implying real hiring activities. Analytical compensation figures are standardized as synthetic annual INR-equivalent benchmarks. All predictive outputs are model-based statistical estimates and do not guarantee employment or compensation."
      )
    )
  ),

  # ---------------------------------------------------------------------------
  # TAB 2: MY PROFILE (Centralized Reactive Session State)
  # ---------------------------------------------------------------------------
  nav_panel("My Profile",
    div(style = "max-width: 1100px; margin: 0 auto; padding: 1rem 0.5rem;",
      div(class = "academic-callout",
        tags$strong("Candidate Profile Session State: "),
        "Define your professional attributes below. Saved profile parameters dynamically propagate across Career Matches, Skill Gap, What-If Lab, and Job Description Analyzer."
      ),
      fluidRow(
        column(5,
          card(
            card_header("Candidate Profile Inputs"),
            card_body(
              selectizeInput("prof_skills", "Current Skills (Select or type to add)",
                choices = all_skills,
                selected = c("Python", "SQL", "Excel"),
                multiple = TRUE,
                options = list(plugins = list("remove_button"), create = TRUE)
              ),
              sliderInput("prof_exp", "Years of Relevant Experience",
                min = 0, max = 20, value = 2, step = 1, post = " yrs"
              ),
              selectInput("prof_edu", "Highest Education Level",
                choices = choices_education, selected = "B.Tech"
              ),
              selectInput("prof_loc", "Preferred Location",
                choices = c("All Locations", choices_location[choices_location != "All"]),
                selected = "Bengaluru"
              ),
              selectInput("prof_role", "Target Career Role (Primary Focus)",
                choices = choices_roles_only, selected = "Data Analyst"
              ),
              hr(),
              actionButton("prof_save_btn", "Save Profile for Session", class = "btn btn-primary w-100 mb-2"),
              actionButton("prof_reset_btn", "Reset to Default Demo Profile", class = "btn btn-outline-secondary w-100")
            )
          )
        ),
        column(7,
          card(
            card_header("Active Profile Summary"),
            card_body(
              uiOutput("prof_active_summary_ui"),
              hr(),
              tags$h6("Next Career Actions:"),
              div(class = "d-flex gap-2 mt-2",
                actionButton("prof_to_matches_btn", "Explore Career Matches →", class = "btn btn-outline-primary"),
                actionButton("prof_to_whatif_btn", "Open Skill Gap & What-If Lab →", class = "btn btn-outline-success")
              )
            )
          )
        )
      )
    )
  ),

  # ---------------------------------------------------------------------------
  # TAB 3: CAREER MATCHES (Role Rankings, Fit Breakdown & Path Comparison)
  # ---------------------------------------------------------------------------
  nav_panel("Career Matches",
    layout_sidebar(
      sidebar = sidebar(
        width = 240,
        tags$p("Career Matching Scope", class = "sidebar-heading"),
        selectInput("cm_selected_role", "Focus Role for Detailed Match", choices = choices_roles_only, selected = "Data Analyst"),
        hr(),
        tags$p("Role Path Comparison", class = "sidebar-heading"),
        selectInput("cmp_role_a", "Career A", choices = choices_roles_only, selected = "Data Analyst"),
        selectInput("cmp_role_b", "Career B", choices = choices_roles_only, selected = "Data Scientist")
      ),
      navset_card_tab(
        nav_panel("A. Ranked Career Matches",
          div(class = "academic-callout",
            tags$strong("Methodology: "), "Roles with >= 50 job postings are evaluated against your saved profile. Shortlist is ranked primarily by ",
            tags$strong("Posting-Level Overlap (>=80%)"), " (proportion of postings where you satisfy at least 80% of required skills), with ",
            tags$strong("Demand-Weighted Skill Coverage"), " as secondary tie-breaker."
          ),
          card(card_header("Career Match Shortlist"),
            card_body(DTOutput("cm_ranking_dt"))
          )
        ),
        nav_panel("B. Detailed Role Match & Compatibility",
          uiOutput("cm_role_kpi_ui"),
          fluidRow(
            column(7,
              card(card_header("Recognized Role Skills & Your Match Status"),
                card_body(DTOutput("cm_skills_dt"))
              )
            ),
            column(5,
              card(card_header("Experience & Compensation Context"),
                card_body(uiOutput("cm_context_ui"))
              )
            )
          )
        ),
        nav_panel("C. Side-by-Side Career Path Comparison",
          div(class = "academic-callout",
            tags$strong("Comparative Path Analysis: "), "Examine salary distributions, required experience, shared transferable competencies, and specialized requirements between two career trajectories."
          ),
          uiOutput("cmp_summary_cards_ui"),
          fluidRow(
            column(6,
              card(card_header("Shared Transferable Skills Across Both Roles"),
                card_body(DTOutput("cmp_shared_dt"))
              )
            ),
            column(6,
              card(card_header("Distinguishing Competencies (Role-Specific)"),
                card_body(uiOutput("cmp_unique_ui"))
              )
            )
          )
        )
      )
    )
  ),

  # ---------------------------------------------------------------------------
  # TAB 4: SKILL GAP & WHAT-IF LAB (Simulator & Recommendation Engine)
  # ---------------------------------------------------------------------------
  nav_panel("Skill Gap & What-If Lab",
    navset_card_tab(
      nav_panel("A. What-If Skill Simulator",
        div(class = "academic-callout",
          tags$strong("Scenario Experimentation: "), "Test proposed learning additions against your baseline profile. Observe real-time recalculations of coverage, 80% posting overlap, and newly satisfied job postings."
        ),
        fluidRow(
          column(4,
            card(card_header("Proposed Profile Experiment"),
              card_body(
                uiOutput("sim_baseline_badge_ui"),
                selectizeInput("sim_proposed_skills", "Proposed Skill Repertoire (Add or remove skills to test)",
                  choices = all_skills,
                  selected = c("Python", "SQL", "Excel", "Power BI"),
                  multiple = TRUE,
                  options = list(plugins = list("remove_button"), create = TRUE)
                ),
                actionButton("sim_reset_btn", "Reset to Current Baseline", class = "btn btn-sm btn-outline-secondary w-100")
              )
            )
          ),
          column(8,
            uiOutput("sim_delta_kpis_ui"),
            fluidRow(
              column(6,
                card(card_header("Before-and-After Metric Deltas"),
                  card_body(tableOutput("sim_delta_table"))
                )
              ),
              column(6,
                card(card_header("What Changed? (Newly Satisfied Requirements)"),
                  card_body(uiOutput("sim_change_summary_ui"))
                )
              )
            )
          )
        )
      ),
      nav_panel("B. Priority Recommendation Engine",
        div(class = "academic-callout",
          tags$strong("Evidence-Based Prioritization: "), "Missing skills are ranked by the explainable heuristic: ",
          tags$code("Priority Index = 0.70 × Role Demand % + 0.30 × Market Demand %"),
          ". Empirical co-occurrence calculates how often the missing requirement appears alongside your current profile skills in actual postings."
        ),
        card(card_header("Prioritized Learning Recommendations"),
          card_body(
            DTOutput("rec_table_dt"),
            hr(),
            downloadButton("dl_recs_csv", "Download Recommendations Report (CSV)", class = "btn btn-outline-primary")
          )
        )
      )
    )
  ),

  # ---------------------------------------------------------------------------
  # TAB 5: JOB DESCRIPTION ANALYZER (Boundary-Aware Regex Extraction)
  # ---------------------------------------------------------------------------
  nav_panel("Job Description Analyzer",
    layout_sidebar(
      sidebar = sidebar(
        width = 250,
        tags$p("Analysis Parameters", class = "sidebar-heading"),
        selectInput("jd_target_role", "Target Role Benchmark", choices = choices_roles_only, selected = "Data Analyst"),
        tags$p(class = "text-muted small", "Skills extracted from the job description are cross-referenced with your profile and the selected role benchmark.")
      ),
      card(card_header("Paste Real Job Description"),
        card_body(
          textAreaInput("jd_raw_text", label = NULL,
            value = "We are looking for a Data Analyst proficient in Python, SQL, and Excel. Hands-on experience with Power BI, Tableau, and AWS is highly desired. Knowledge of Docker, C++, and statistics is a plus.",
            height = "140px",
            placeholder = "Paste raw job description text here..."
          ),
          div(class = "d-flex gap-2",
            actionButton("jd_run_btn", "Analyze Job Description", class = "btn btn-primary"),
            actionButton("jd_clear_btn", "Clear Text", class = "btn btn-outline-secondary")
          )
        )
      ),
      uiOutput("jd_results_ui")
    )
  ),

  # ---------------------------------------------------------------------------
  # TAB 6: SALARY & PREDICTION LAB (SLR, MLR, Logistic & Scenario Simulator)
  # ---------------------------------------------------------------------------
  nav_panel("Salary & Prediction Lab",
    navset_card_tab(
      nav_panel("A. Simple Linear Regression",
        div(class = "academic-callout",
          tags$strong("Model Specification: "), tags$code("lm(salary_inr ~ experience_years)"),
          " | Partition: 80% Train / 20% Held-Out Test (seed = 42). Missing salary observations strictly excluded from modeling."
        ),
        fluidRow(
          column(5,
            card(card_header("Model Summary & Evaluation Metrics"),
              card_body(tableOutput("slr_metrics_table"))
            ),
            card(card_header("Regression Equation"),
              card_body(uiOutput("slr_equation_box"))
            )
          ),
          column(7,
            card(card_header("Experience vs. Salary (INR) with 95% Fit Band"),
              card_body(plotlyOutput("slr_plot", height = 340))
            )
          )
        )
      ),
      nav_panel("B. Multiple Linear Regression",
        div(class = "academic-callout",
          tags$strong("Model Specification: "), tags$code("salary_inr ~ experience_years + skill_count + education + company_size_num + location_tier"),
          " | Evaluated on 20% holdout test partition with residual diagnostics."
        ),
        fluidRow(
          column(5,
            card(card_header("Model Performance & Test Set Error"),
              card_body(tableOutput("mlr_metrics_table"))
            ),
            card(card_header("Model Coefficients"),
              card_body(DTOutput("mlr_coef_dt"))
            )
          ),
          column(7,
            card(card_header("Actual vs. Predicted Salary (Test Set Holdout)"),
              card_body(plotlyOutput("mlr_act_pred_plot", height = 260))
            ),
            card(card_header("Residual Diagnostics (Fitted vs. Standardized Residuals)"),
              card_body(plotlyOutput("mlr_resid_plot", height = 240))
            )
          )
        )
      ),
      nav_panel("C. Logistic Classification",
        div(class = "academic-callout",
          tags$strong("Model Specification: "), tags$code("glm(high_salary ~ predictors, family = binomial)"),
          " | High-salary threshold (INR ", textOutput("logit_thresh_txt", inline = TRUE), ") calculated strictly from training split to prevent data leakage."
        ),
        fluidRow(
          column(6,
            card(card_header("Out-of-Sample Test Evaluation (20% Holdout)"),
              card_body(tableOutput("logit_metrics_table"))
            ),
            card(card_header("Out-of-Sample Confusion Matrix"),
              card_body(tableOutput("logit_cm_table"))
            )
          ),
          column(6,
            card(card_header("Model Coefficients (Log-Odds)"),
              card_body(DTOutput("logit_coef_dt"))
            )
          )
        )
      ),
      nav_panel("D. Interactive Scenario Simulator",
        div(class = "academic-callout",
          tags$strong("Interactive Scenario Estimation: "), "Enter candidate predictors to compute salary estimates, 95% prediction intervals, and high-salary probabilities."
        ),
        fluidRow(
          column(4,
            card(card_header("Scenario Input Controls"),
              card_body(
                sliderInput("pred_exp", "Experience (Years)", min = 0, max = 25, value = 4),
                sliderInput("pred_skills", "Skill Count", min = 1, max = 15, value = 6),
                selectInput("pred_edu", "Education Level", choices = choices_education, selected = "B.Tech"),
                selectInput("pred_size", "Company Size", choices = choices_company_size, selected = "Large"),
                selectInput("pred_loc_tier", "Location Tier", choices = c("Tier 1", "Tier 2", "Tier 3"), selected = "Tier 1")
              )
            )
          ),
          column(8,
            uiOutput("pred_extrap_alert"),
            fluidRow(
              column(6,
                card(card_header("Multiple Linear Regression Estimate"),
                  card_body(
                    div(class = "pred-result-box",
                      tags$p("Estimated Annual Salary (Point Estimate)", class = "kpi-label"),
                      tags$h3(textOutput("pred_mlr_point"), class = "kpi-value"),
                      tags$p(class = "text-muted small mt-1", "95% Prediction Interval:"),
                      tags$strong(textOutput("pred_mlr_interval", inline = TRUE))
                    )
                  )
                )
              ),
              column(6,
                card(card_header("Logistic High-Salary Probability"),
                  card_body(
                    div(class = "pred-result-box",
                      tags$p("Probability of Salary >= Training Median", class = "kpi-label"),
                      tags$h3(textOutput("pred_logit_prob"), class = "kpi-value"),
                      tags$p(class = "text-muted small mt-1", "Classification:"),
                      tags$strong(textOutput("pred_logit_class", inline = TRUE))
                    )
                  )
                )
              )
            ),
            div(class = "academic-disclaimer",
              tags$strong("Statistical Estimation Notice: "),
              "Point estimates and prediction intervals are model-based statistical approximations reflecting training variance and residual standard error. They illustrate general patterns and do not guarantee an employment offer or compensation."
            )
          )
        )
      )
    )
  ),

  # ---------------------------------------------------------------------------
  # TAB 7: MARKET EVIDENCE & DATA QUALITY (Distributions, Heatmaps & Audit)
  # ---------------------------------------------------------------------------
  nav_panel("Market Evidence & Data Quality",
    layout_sidebar(
      sidebar = sidebar(
        width = 230,
        tags$p("Evidence Filter Scope", class = "sidebar-heading"),
        selectInput("ev_location", "Location", choices = choices_location),
        selectInput("ev_title", "Job Role", choices = choices_title),
        selectInput("ev_industry", "Industry", choices = choices_industry),
        actionButton("ev_reset", "Reset Filters", class = "btn btn-sm btn-outline-secondary w-100 mt-2")
      ),
      navset_card_tab(
        nav_panel("A. Exploratory Distributions",
          fluidRow(
            column(6, card(card_header("Top In-Demand Skills"), card_body(plotlyOutput("ev_skills_bar", height = 310)))),
            column(6, card(card_header("Job Postings by Role"), card_body(plotlyOutput("ev_roles_bar", height = 310))))
          ),
          fluidRow(
            column(6, card(card_header("Salary Distribution by Role (₹ Lakhs)"), card_body(plotlyOutput("ev_sal_box", height = 300)))),
            column(6, card(card_header("Experience Distribution (Years)"), card_body(plotlyOutput("ev_exp_hist", height = 300))))
          )
        ),
        nav_panel("B. Pearson Correlation Heatmap",
          fluidRow(
            column(7, card(card_header("Pearson Correlation Heatmap"), card_body(plotOutput("ev_cor_plot", height = 360)))),
            column(5,
              card(card_header("Correlation Coefficients"), card_body(tableOutput("ev_cor_tbl"))),
              card(card_header("Statistical Interpretation"), card_body(uiOutput("ev_cor_interp")))
            )
          )
        ),
        nav_panel("C. Data Quality & Audit Report",
          fluidRow(
            column(6, card(card_header("Dataset Cleaning & Transformation Summary"), card_body(tableOutput("ev_dq_summary")))),
            column(6, card(card_header("Missing Values per Column (Raw Dataset)"), card_body(DTOutput("ev_missing_dt"))))
          ),
          card(card_header("Cleaned Dataset Preview (First 300 Rows)"),
            card_body(DTOutput("ev_preview_dt"))
          ),
          fluidRow(
            column(4, downloadButton("dl_raw_csv", "Download Raw CSV (6,030 rows)", class = "btn btn-outline-secondary w-100")),
            column(4, downloadButton("dl_clean_csv", "Download Cleaned CSV (6,000 rows)", class = "btn btn-outline-primary w-100"))
          )
        )
      )
    )
  )
)

# =============================================================================
# 4. SERVER LOGIC
# =============================================================================
server <- function(input, output, session) {

  # ---------------------------------------------------------------------------
  # CANDIDATE PROFILE REACTIVE STATE (Shared across all decision modules)
  # ---------------------------------------------------------------------------
  user_profile <- reactiveVal(list(
    skills     = c("Python", "SQL", "Excel"),
    experience = 2,
    education  = "B.Tech",
    location   = "Bengaluru",
    target_role= "Data Analyst"
  ))

  # Save profile action
  observeEvent(input$prof_save_btn, {
    req(input$prof_skills)
    user_profile(list(
      skills     = normalize_candidate_skills(input$prof_skills),
      experience = as.numeric(input$prof_exp),
      education  = input$prof_edu,
      location   = input$prof_loc,
      target_role= input$prof_role
    ))
    showNotification("Candidate profile saved for this session!", type = "message", duration = 3)
  })

  # Reset profile action
  observeEvent(input$prof_reset_btn, {
    updateSelectizeInput(session, "prof_skills", selected = c("Python", "SQL", "Excel"))
    updateSliderInput(session, "prof_exp", value = 2)
    updateSelectInput(session, "prof_edu", selected = "B.Tech")
    updateSelectInput(session, "prof_loc", selected = "Bengaluru")
    updateSelectInput(session, "prof_role", selected = "Data Analyst")
    user_profile(list(
      skills     = c("Python", "SQL", "Excel"),
      experience = 2,
      education  = "B.Tech",
      location   = "Bengaluru",
      target_role= "Data Analyst"
    ))
    showNotification("Profile reset to default demo parameters.", type = "default", duration = 3)
  })

  # Navigation shortcut buttons
  observeEvent(input$home_to_profile_btn, {
    updateNavbarPage(session, "main_nav", selected = "My Profile")
  })
  observeEvent(input$prof_to_matches_btn, {
    updateNavbarPage(session, "main_nav", selected = "Career Matches")
  })
  observeEvent(input$prof_to_whatif_btn, {
    updateNavbarPage(session, "main_nav", selected = "Skill Gap & What-If Lab")
  })

  # Render Active Profile Summary Card
  output$prof_active_summary_ui <- renderUI({
    prof <- user_profile()
    tagList(
      div(class = "d-flex justify-content-between align-items-center mb-2",
        tags$h5(paste0("Target Role: ", prof$target_role), style = "color: #1E6091; font-weight: 700; margin: 0;"),
        tags$span(class = "badge bg-secondary", paste0(length(prof$skills), " Skills Recorded"))
      ),
      tags$p(class = "text-muted small",
        sprintf("Experience: %d years | Education: %s | Location: %s",
                prof$experience, prof$education, prof$location)
      ),
      tags$h6("Saved Skill Inventory:", class = "mt-3"),
      div(class = "d-flex flex-wrap gap-1 mt-1",
        lapply(prof$skills, function(s) tags$span(class = "badge-matched", s))
      )
    )
  })

  # ---------------------------------------------------------------------------
  # TAB 3: CAREER MATCHES OUTPUTS
  # ---------------------------------------------------------------------------
  career_matches_data <- reactive({
    prof <- user_profile()
    rank_career_matches(df_clean, prof$skills, min_postings = 50)
  })

  output$cm_ranking_dt <- renderDT({
    df_ranks <- career_matches_data()
    if (nrow(df_ranks) == 0) return(datatable(data.frame(Message = "No matching roles found.")))

    df_disp <- df_ranks |>
      dplyr::rename(
        `Job Role`                  = Job_Role,
        `Postings Evaluated`        = Posting_Count,
        `Posting Overlap (>=80%)`   = Posting_Overlap_80,
        `Demand-Weighted Cov (%)`   = Weighted_Coverage,
        `Distinct Skill Cov (%)`    = Distinct_Coverage,
        `Posting Overlap (>=50%)`   = Overlap_50,
        `Matched Skills`            = Matched_Count,
        `Missing Skills`            = Missing_Count,
        `Role Median Salary (INR)`  = Median_Salary
      )

    datatable(df_disp, rownames = FALSE,
              options = list(pageLength = 8, order = list(list(2, "desc"))),
              class = "table table-sm table-hover") |>
      formatCurrency("Role Median Salary (INR)", currency = "₹ ", interval = 3, mark = ",", digits = 0) |>
      formatStyle("Posting Overlap (>=80%)",
        background = styleColorBar(range(df_disp$`Posting Overlap (>=80%)`, na.rm = TRUE), "#d0e7f9"),
        backgroundSize = "98% 88%", backgroundRepeat = "no-repeat", backgroundPosition = "center"
      )
  })

  selected_role_match <- reactive({
    prof <- user_profile()
    target_r <- input$cm_selected_role
    calculate_candidate_role_match(df_clean, prof$skills, target_r, candidate_exp = prof$experience)
  })

  output$cm_role_kpi_ui <- renderUI({
    m <- selected_role_match()
    fluidRow(
      column(3, div(class = "kpi-card",
        tags$p("Distinct Skill Coverage", class = "kpi-label"),
        tags$h3(paste0(m$skill_coverage, "%"), class = "kpi-value"),
        tags$div(class = "kpi-subtext", paste0(length(m$matched_skills), " of ", length(m$matched_skills) + length(m$missing_skills), " role skills"))
      )),
      column(3, div(class = "kpi-card",
        tags$p("Demand-Weighted Coverage", class = "kpi-label"),
        tags$h3(paste0(m$weighted_coverage, "%"), class = "kpi-value"),
        tags$div(class = "kpi-subtext", "Weighted by role frequency")
      )),
      column(3, div(class = "kpi-card",
        tags$p("Posting Overlap (>=80%)", class = "kpi-label"),
        tags$h3(paste0(m$overlap_ge_80, "%"), class = "kpi-value"),
        tags$div(class = "kpi-subtext", paste0(">=50% overlap: ", m$overlap_ge_50, "%"))
      )),
      column(3, div(class = "kpi-card",
        tags$p("Role Median Salary", class = "kpi-label"),
        tags$h3(format_inr(m$salary_context$median), class = "kpi-value"),
        tags$div(class = "kpi-subtext", paste0("IQR: ", format_inr(m$salary_context$q1), " - ", format_inr(m$salary_context$q3)))
      ))
    )
  })

  output$cm_skills_dt <- renderDT({
    m <- selected_role_match()
    if (nrow(m$skills_breakdown) == 0) return(datatable(data.frame()))

    df_disp <- m$skills_breakdown |>
      dplyr::select(
        Skill           = skill,
        Category        = skill_category,
        Status          = status,
        `Role Postings` = postings_count,
        `Role Demand %` = demand_pct
      )

    datatable(df_disp, rownames = FALSE, options = list(pageLength = 8), class = "table table-sm table-hover") |>
      formatStyle("Status",
        color = styleEqual(c("Matched", "Missing"), c(GREEN, RED)),
        fontWeight = "bold"
      )
  })

  output$cm_context_ui <- renderUI({
    m <- selected_role_match()
    prof <- user_profile()
    sal <- m$salary_context
    exp_c <- m$exp_compatibility

    tagList(
      tags$h6("Experience Compatibility:"),
      tags$p(class = "small",
        sprintf("Candidate experience (%d yrs) qualifies for %.1f%% of observed %s postings (role average required experience: %.1f yrs).",
                prof$experience, exp_c$pct_qualified, m$target_role, exp_c$role_mean_exp)
      ),
      hr(),
      tags$h6("Role Compensation Distribution:"),
      tags$ul(class = "small text-muted",
        tags$li(paste0("10th Percentile: ", format_inr(sal$p10))),
        tags$li(paste0("25th Percentile (Q1): ", format_inr(sal$q1))),
        tags$li(paste0("Median (50th): ", format_inr(sal$median))),
        tags$li(paste0("75th Percentile (Q3): ", format_inr(sal$q3))),
        tags$li(paste0("90th Percentile: ", format_inr(sal$p90))),
        tags$li(paste0("Interquartile Range (IQR): ", format_inr(sal$iqr)))
      ),
      if (!is.null(m$warning_msg)) div(class = "alert alert-warning py-1 small", m$warning_msg)
    )
  })

  # Side-by-side Career Path Comparison
  path_cmp_data <- reactive({
    prof <- user_profile()
    compare_career_paths(df_clean, input$cmp_role_a, input$cmp_role_b, prof$skills)
  })

  output$cmp_summary_cards_ui <- renderUI({
    cmp <- path_cmp_data()
    if (cmp$is_same_role) {
      return(div(class = "alert alert-warning", cmp$error_msg))
    }

    fluidRow(
      column(6,
        card(card_header(paste0("Career A: ", cmp$role_a)),
          card_body(
            tags$p(paste0("Postings Analyzed: ", cmp$postings_a)),
            tags$p(paste0("Median Salary: ", format_inr(cmp$salary_a$median))),
            tags$p(paste0("Average Required Experience: ", cmp$exp_mean_a, " yrs")),
            tags$p(paste0("Candidate Distinct Skill Coverage: ", cmp$fit_a$skill_coverage, "%")),
            tags$p(paste0("Candidate Posting Overlap (>=80%): ", cmp$fit_a$overlap_ge_80, "%"))
          )
        )
      ),
      column(6,
        card(card_header(paste0("Career B: ", cmp$role_b)),
          card_body(
            tags$p(paste0("Postings Analyzed: ", cmp$postings_b)),
            tags$p(paste0("Median Salary: ", format_inr(cmp$salary_b$median))),
            tags$p(paste0("Average Required Experience: ", cmp$exp_mean_b, " yrs")),
            tags$p(paste0("Candidate Distinct Skill Coverage: ", cmp$fit_b$skill_coverage, "%")),
            tags$p(paste0("Candidate Posting Overlap (>=80%): ", cmp$fit_b$overlap_ge_80, "%"))
          )
        )
      )
    )
  })

  output$cmp_shared_dt <- renderDT({
    cmp <- path_cmp_data()
    if (cmp$is_same_role || length(cmp$shared_skills) == 0) return(datatable(data.frame()))

    df_sh <- data.frame(
      Skill = cmp$shared_skills,
      Category = sapply(cmp$shared_skills, get_skill_category),
      `Your Match Status` = ifelse(cmp$shared_skills %in% cmp$candidate_shared_matched, "Matched", "Missing"),
      check.names = FALSE,
      stringsAsFactors = FALSE
    )
    datatable(df_sh, rownames = FALSE, options = list(pageLength = 8), class = "table table-sm table-hover") |>
      formatStyle("Your Match Status", color = styleEqual(c("Matched", "Missing"), c(GREEN, RED)), fontWeight = "bold")
  })

  output$cmp_unique_ui <- renderUI({
    cmp <- path_cmp_data()
    if (cmp$is_same_role) return(NULL)

    tagList(
      tags$h6(paste0("Unique Competencies for ", cmp$role_a, ":")),
      if (length(cmp$unique_to_a) > 0) {
        div(class = "d-flex flex-wrap gap-1 mb-3",
          lapply(head(cmp$unique_to_a, 10), function(s) tags$span(class = "badge bg-light text-dark border", s))
        )
      } else {
        tags$p(class = "small text-muted", "No unique competencies identified.")
      },
      tags$h6(paste0("Unique Competencies for ", cmp$role_b, ":")),
      if (length(cmp$unique_to_b) > 0) {
        div(class = "d-flex flex-wrap gap-1",
          lapply(head(cmp$unique_to_b, 10), function(s) tags$span(class = "badge bg-light text-dark border", s))
        )
      } else {
        tags$p(class = "small text-muted", "No unique competencies identified.")
      }
    )
  })

  # ---------------------------------------------------------------------------
  # TAB 4: WHAT-IF SIMULATOR & RECOMMENDATIONS OUTPUTS
  # ---------------------------------------------------------------------------
  output$sim_baseline_badge_ui <- renderUI({
    prof <- user_profile()
    div(class = "mb-2",
      tags$strong("Current Baseline Profile: "),
      div(class = "d-flex flex-wrap gap-1 mt-1",
        lapply(prof$skills, function(s) tags$span(class = "badge bg-secondary", s))
      )
    )
  })

  observeEvent(input$sim_reset_btn, {
    prof <- user_profile()
    updateSelectizeInput(session, "sim_proposed_skills", selected = prof$skills)
  })

  what_if_sim_data <- reactive({
    prof <- user_profile()
    proposed <- normalize_candidate_skills(input$sim_proposed_skills)
    simulate_profile_change(df_clean, prof$skills, proposed, prof$target_role)
  })

  output$sim_delta_kpis_ui <- renderUI({
    sim <- what_if_sim_data()
    fluidRow(
      column(4, div(class = "kpi-card",
        tags$p("Skill Coverage Delta", class = "kpi-label"),
        tags$h3(paste0(ifelse(sim$coverage_delta >= 0, "+", ""), sim$coverage_delta, "%"),
                class = ifelse(sim$coverage_delta >= 0, "kpi-value text-success", "kpi-value text-danger")),
        tags$div(class = "kpi-subtext", paste0("Baseline: ", sim$baseline_coverage, "% → Proposed: ", sim$proposed_coverage, "%"))
      )),
      column(4, div(class = "kpi-card",
        tags$p("Posting Overlap (>=80%) Delta", class = "kpi-label"),
        tags$h3(paste0(ifelse(sim$overlap_delta >= 0, "+", ""), sim$overlap_delta, "%"),
                class = ifelse(sim$overlap_delta >= 0, "kpi-value text-success", "kpi-value text-danger")),
        tags$div(class = "kpi-subtext", paste0("Baseline: ", sim$baseline_overlap, "% → Proposed: ", sim$proposed_overlap, "%"))
      )),
      column(4, div(class = "kpi-card",
        tags$p("Newly Satisfied Postings", class = "kpi-label"),
        tags$h3(paste0("+", sim$newly_satisfied_postings), class = "kpi-value text-primary"),
        tags$div(class = "kpi-subtext", "Postings elevated to >=80% overlap")
      ))
    )
  })

  output$sim_delta_table <- renderTable({
    sim <- what_if_sim_data()
    data.frame(
      Metric = c("Distinct Skill Coverage (%)", "Demand-Weighted Coverage (%)",
                 "Posting Overlap >= 80% (%)", "Posting Overlap >= 50% (%)",
                 "Matched Role Skills Count"),
      `Baseline Profile` = c(paste0(sim$baseline_coverage, "%"), paste0(sim$baseline_weighted_cov, "%"),
                             paste0(sim$baseline_overlap, "%"), paste0(sim$baseline_overlap_50, "%"),
                             as.character(sim$baseline_matched_count)),
      `Proposed Profile` = c(paste0(sim$proposed_coverage, "%"), paste0(sim$proposed_weighted_cov, "%"),
                             paste0(sim$proposed_overlap, "%"), paste0(sim$proposed_overlap_50, "%"),
                             as.character(sim$proposed_matched_count)),
      `Net Delta`        = c(sprintf("%+.1f%%", sim$coverage_delta), sprintf("%+.1f%%", sim$weighted_coverage_delta),
                             sprintf("%+.1f%%", sim$overlap_delta), sprintf("%+.1f%%", sim$proposed_overlap_50 - sim$baseline_overlap_50),
                             sprintf("%+d", sim$proposed_matched_count - sim$baseline_matched_count)),
      check.names = FALSE
    )
  }, striped = TRUE, bordered = TRUE)

  output$sim_change_summary_ui <- renderUI({
    sim <- what_if_sim_data()
    tagList(
      tags$h6("Newly Matched Requirements:"),
      if (length(sim$newly_matched_role_skills) > 0) {
        div(class = "d-flex flex-wrap gap-1 mb-2",
          lapply(sim$newly_matched_role_skills, function(s) tags$span(class = "badge-matched", paste0("+ ", s)))
        )
      } else {
        tags$p(class = "small text-muted", "None of the newly added skills matched remaining target-role requirements.")
      },
      tags$h6("Remaining Missing Role Gaps:", class = "mt-3"),
      if (nrow(sim$remaining_missing_tbl) > 0) {
        tags$ol(class = "small text-muted ps-3",
          lapply(head(sim$remaining_missing_tbl$skill, 5), function(s) tags$li(s))
        )
      } else {
        tags$p(class = "small text-success", "✓ All recognized skills for this role are satisfied in the proposed profile!")
      }
    )
  })

  # Recommendation Engine outputs
  rec_engine_data <- reactive({
    prof <- user_profile()
    calculate_recommendation_priorities(df_clean, prof$skills, prof$target_role)
  })

  output$rec_table_dt <- renderDT({
    res <- rec_engine_data()
    df_recs <- res$recommendations_tbl
    if (nrow(df_recs) == 0) return(datatable(data.frame(Message = "No missing skills recommended.")))

    df_disp <- df_recs |>
      dplyr::select(
        Skill                   = skill,
        `Priority Category`     = priority_category,
        `Priority Index`        = priority_index,
        `Role Demand %`         = role_demand_pct,
        `Role Postings`         = role_postings,
        `Market Demand %`       = market_demand_pct,
        `Observed Co-occurrence`= cooccurring_skills,
        `Evidence & Rationale`  = narrative_explanation
      )

    datatable(df_disp, rownames = FALSE,
              options = list(pageLength = 8, order = list(list(2, "desc"))),
              class = "table table-sm table-hover") |>
      formatStyle("Priority Category",
        color = styleEqual(c("HIGH PRIORITY", "MEDIUM PRIORITY", "ADDITIONAL SKILL"), c(RED, AMBER, GREY)),
        fontWeight = "bold"
      )
  })

  output$dl_recs_csv <- downloadHandler(
    filename = function() { paste0("careerlens_recommendations_", Sys.Date(), ".csv") },
    content = function(file) {
      write.csv(export_recommendations_csv(rec_engine_data()), file, row.names = FALSE)
    }
  )

  # ---------------------------------------------------------------------------
  # TAB 5: JOB DESCRIPTION ANALYZER OUTPUTS
  # ---------------------------------------------------------------------------
  jd_analysis_data <- eventReactive(input$jd_run_btn, {
    req(input$jd_raw_text)
    prof <- user_profile()
    analyze_job_description(input$jd_raw_text, prof$skills, input$jd_target_role, df_clean, skill_dict)
  }, ignoreNULL = FALSE)

  observeEvent(input$jd_clear_btn, {
    updateTextAreaInput(session, "jd_raw_text", value = "")
  })

  output$jd_results_ui <- renderUI({
    res <- jd_analysis_data()
    if (!res$has_skills) {
      return(div(class = "alert alert-warning mt-3", res$disclaimer))
    }

    tagList(
      fluidRow(
        column(4, div(class = "kpi-card",
          tags$p("Extracted Recognized Skills", class = "kpi-label"),
          tags$h3(res$extracted_count, class = "kpi-value")
        )),
        column(4, div(class = "kpi-card",
          tags$p("Matched Profile Skills", class = "kpi-label"),
          tags$h3(length(res$matched_skills), class = "kpi-value text-success")
        )),
        column(4, div(class = "kpi-card",
          tags$p("Missing Requirements", class = "kpi-label"),
          tags$h3(length(res$missing_skills), class = "kpi-value text-danger")
        ))
      ),
      card(card_header("Extracted Skills Analysis & Market Benchmarking"),
        card_body(DTOutput("jd_breakdown_dt"))
      )
    )
  })

  output$jd_breakdown_dt <- renderDT({
    res <- jd_analysis_data()
    if (!res$has_skills) return(datatable(data.frame()))
    datatable(res$breakdown_tbl, rownames = FALSE, options = list(pageLength = 8), class = "table table-sm table-hover") |>
      formatStyle("Status", color = styleEqual(c("Matched", "Missing"), c(GREEN, RED)), fontWeight = "bold")
  })

  # ---------------------------------------------------------------------------
  # TAB 6: SALARY & PREDICTION LAB OUTPUTS
  # ---------------------------------------------------------------------------
  output$slr_metrics_table <- renderTable({
    data.frame(
      Metric = c("Sample Size (Valid Salary)", "Training R-squared", "Adjusted R-squared",
                 "Holdout Test R-squared", "Test Root Mean Sq Error (RMSE)", "Test Mean Absolute Error (MAE)",
                 "F-Statistic", "p-value"),
      Value  = c(
        format(nrow(slr_res$train_data) + nrow(slr_res$test_data), big.mark = ","),
        as.character(slr_res$train_r2),
        as.character(slr_res$train_adj_r2),
        as.character(slr_res$test_r2),
        format_inr(slr_res$test_rmse),
        format_inr(slr_res$test_mae),
        as.character(slr_res$f_stat),
        format.pval(slr_res$p_value, eps = 0.001)
      )
    )
  }, striped = TRUE, bordered = TRUE)

  output$slr_equation_box <- renderUI({
    div(class = "p-2 bg-light border rounded text-center",
      tags$code(style = "font-size: 1.05rem; font-weight: bold; color: #1E6091;", slr_res$equation)
    )
  })

  output$slr_plot <- renderPlotly({
    p <- ggplot(slr_res$train_data, aes(x = experience_years, y = salary_inr / 100000)) +
      geom_point(alpha = 0.25, color = BLUE, size = 1.2) +
      geom_smooth(method = "lm", color = RED, se = TRUE) +
      labs(x = "Experience (Years)", y = "Salary (₹ Lakhs)", title = "Simple Linear Regression Fit") +
      theme_minimal()
    ggplotly(p)
  })

  output$mlr_metrics_table <- renderTable({
    data.frame(
      Metric = c("Training Partition R²", "Adjusted R²", "Holdout Test R²",
                 "Test RMSE", "Test MAE", "F-Statistic", "p-value"),
      Value  = c(
        as.character(mlr_res$train_r2),
        as.character(mlr_res$train_adj_r2),
        as.character(mlr_res$test_r2),
        format_inr(mlr_res$test_rmse),
        format_inr(mlr_res$test_mae),
        as.character(mlr_res$f_stat),
        format.pval(mlr_res$p_value, eps = 0.001)
      )
    )
  }, striped = TRUE, bordered = TRUE)

  output$mlr_coef_dt <- renderDT({
    df_c <- mlr_res$coef_table
    df_c$Predictor <- rownames(df_c)
    df_c <- df_c |> dplyr::select(Predictor, Estimate, `Std. Error`, `t value`, `Pr(>|t|)`)
    datatable(df_c, rownames = FALSE, options = list(pageLength = 6), class = "table table-sm table-hover") |>
      formatRound(c("Estimate", "Std. Error", "t value"), 2) |>
      formatSignif("Pr(>|t|)", 3)
  })

  output$mlr_act_pred_plot <- renderPlotly({
    preds <- predict(mlr_res$model, newdata = mlr_res$test_data)
    df_plot <- data.frame(Actual = mlr_res$test_data$salary_inr / 100000, Predicted = preds / 100000)
    p <- ggplot(df_plot, aes(x = Actual, y = Predicted)) +
      geom_point(alpha = 0.35, color = BLUE, size = 1.3) +
      geom_abline(slope = 1, intercept = 0, color = RED, linetype = "dashed") +
      labs(x = "Actual Salary (₹ Lakhs)", y = "Predicted Salary (₹ Lakhs)", title = "Actual vs. Predicted (Test Set)") +
      theme_minimal()
    ggplotly(p)
  })

  output$mlr_resid_plot <- renderPlotly({
    diag_df <- head(mlr_res$diagnostics, 1000)
    p <- ggplot(diag_df, aes(x = Fitted / 100000, y = StdResid)) +
      geom_point(alpha = 0.3, color = GREY, size = 1.2) +
      geom_hline(yintercept = 0, color = BLUE) +
      geom_hline(yintercept = c(-2, 2), color = RED, linetype = "dashed") +
      labs(x = "Fitted Salary (₹ Lakhs)", y = "Standardized Residuals", title = "Residual Diagnostics") +
      theme_minimal()
    ggplotly(p)
  })

  output$logit_thresh_txt <- renderText({ format(round(logit_res$threshold), big.mark = ",") })

  output$logit_metrics_table <- renderTable({
    m <- logit_res$test_metrics
    data.frame(
      Metric = c("Test Accuracy (%)", "Sensitivity / Recall (%)", "Specificity (%)",
                 "Precision (%)", "F1 Score (%)", "Akaike Information Criterion (AIC)"),
      Value  = c(paste0(m$accuracy, "%"), paste0(m$sensitivity, "%"), paste0(m$specificity, "%"),
                 paste0(m$precision, "%"), paste0(m$f1_score, "%"), as.character(logit_res$aic))
    )
  }, striped = TRUE, bordered = TRUE)

  output$logit_cm_table <- renderTable({
    as.data.frame.matrix(logit_res$test_cm)
  }, rownames = TRUE, bordered = TRUE)

  output$logit_coef_dt <- renderDT({
    df_c <- logit_res$coef_table
    df_c$Predictor <- rownames(df_c)
    df_c <- df_c |> dplyr::select(Predictor, Estimate, `Std. Error`, `z value`, `Pr(>|z|)`)
    datatable(df_c, rownames = FALSE, options = list(pageLength = 6), class = "table table-sm table-hover") |>
      formatRound(c("Estimate", "Std. Error", "z value"), 3) |>
      formatSignif("Pr(>|z|)", 3)
  })

  # Scenario Prediction Outputs
  scenario_pred <- reactive({
    predict_salary_scenario(
      slr_res, mlr_res, logit_res,
      exp_years = input$pred_exp,
      skill_cnt = input$pred_skills,
      edu_val   = input$pred_edu,
      comp_size = input$pred_size,
      loc_tier  = input$pred_loc_tier
    )
  })

  output$pred_extrap_alert <- renderUI({
    res <- scenario_pred()
    if (!is.null(res$extrap_warn)) {
      div(class = "alert alert-warning py-1 small", res$extrap_warn)
    } else {
      NULL
    }
  })

  output$pred_mlr_point <- renderText({
    res <- scenario_pred()
    format_inr(res$mlr_estimate)
  })

  output$pred_mlr_interval <- renderText({
    res <- scenario_pred()
    paste0(format_inr(res$mlr_lwr), " — ", format_inr(res$mlr_upr))
  })

  output$pred_logit_prob <- renderText({
    res <- scenario_pred()
    paste0(res$high_sal_prob, "%")
  })

  output$pred_logit_class <- renderText({
    res <- scenario_pred()
    res$high_sal_label
  })

  # ---------------------------------------------------------------------------
  # TAB 7: MARKET EVIDENCE & DATA QUALITY OUTPUTS
  # ---------------------------------------------------------------------------
  ev_filtered_df <- reactive({
    apply_filters(df_clean, location = input$ev_location, title = input$ev_title, industry = input$ev_industry)
  })

  observeEvent(input$ev_reset, {
    updateSelectInput(session, "ev_location", selected = "All")
    updateSelectInput(session, "ev_title", selected = "All")
    updateSelectInput(session, "ev_industry", selected = "All")
  })

  output$ev_skills_bar <- renderPlotly({
    df <- ev_filtered_df()
    if (nrow(df) == 0) return(no_data_plotly())
    top_s <- head(calculate_skill_demand(df), 12)
    p <- ggplot(top_s, aes(x = reorder(skill, job_count), y = job_count)) +
      geom_col(fill = BLUE) + coord_flip() +
      labs(x = NULL, y = "Postings Count") + theme_minimal()
    ggplotly(p)
  })

  output$ev_roles_bar <- renderPlotly({
    df <- ev_filtered_df()
    if (nrow(df) == 0) return(no_data_plotly())
    role_c <- df |> dplyr::count(job_title) |> dplyr::arrange(dplyr::desc(n)) |> head(10)
    p <- ggplot(role_c, aes(x = reorder(job_title, n), y = n)) +
      geom_col(fill = BLUE) + coord_flip() +
      labs(x = NULL, y = "Postings Count") + theme_minimal()
    ggplotly(p)
  })

  output$ev_sal_box <- renderPlotly({
    df <- ev_filtered_df() |> dplyr::filter(!is.na(salary_inr), salary_outlier == 0)
    if (nrow(df) == 0) return(no_data_plotly())
    top_r <- names(head(sort(table(df$job_title), decreasing = TRUE), 6))
    df_sub <- df |> dplyr::filter(as.character(job_title) %in% top_r)
    p <- ggplot(df_sub, aes(x = job_title, y = salary_inr / 100000)) +
      geom_boxplot(fill = "#d0e7f9", color = BLUE) + coord_flip() +
      labs(x = NULL, y = "Salary (₹ Lakhs)") + theme_minimal()
    ggplotly(p)
  })

  output$ev_exp_hist <- renderPlotly({
    df <- ev_filtered_df()
    if (nrow(df) == 0) return(no_data_plotly())
    p <- ggplot(df, aes(x = experience_years)) +
      geom_histogram(binwidth = 1, fill = BLUE, color = "white") +
      labs(x = "Experience (Years)", y = "Postings Count") + theme_minimal()
    ggplotly(p)
  })

  # Correlation Heatmap
  cor_df <- reactive({
    df_clean |>
      dplyr::filter(!is.na(salary_inr), !is.na(experience_years)) |>
      dplyr::select(
        `Exp. Years`  = experience_years,
        `Salary (INR)`= salary_inr,
        `Skill Count` = skill_count,
        `Co. Size`    = company_size_num
      )
  })

  output$ev_cor_plot <- renderPlot({
    cm <- cor(cor_df(), method = "pearson")
    corrplot(cm, method = "color", type = "upper", addCoef.col = "black",
             tl.col = "black", tl.srt = 45, col = colorRampPalette(c("#d97706", "white", "#1E6091"))(100))
  })

  output$ev_cor_tbl <- renderTable({
    cm <- round(cor(cor_df(), method = "pearson"), 3)
    as.data.frame(cm)
  }, rownames = TRUE, bordered = TRUE)

  output$ev_cor_interp <- renderUI({
    tagList(
      tags$p(class = "small",
        tags$strong("Experience vs. Salary: "),
        "Strong positive Pearson correlation (~0.65) reflects typical industry seniority compensation premiums."
      ),
      tags$p(class = "small",
        tags$strong("Skill Count vs. Salary: "),
        "Moderate positive correlation (~0.25) aligns with demand for versatile multi-domain practitioners."
      )
    )
  })

  # Data Quality Outputs
  output$ev_dq_summary <- renderTable({
    data.frame(
      Metric = c("Raw Postings Generated", "Duplicate Rows Removed", "Total Missing Values Handled",
                 "Clean Records Analyzed", "Preserved Missing Salaries (NA)", "Clean Columns"),
      Value  = c(
        format(qr$raw_rows, big.mark = ","),
        format(qr$n_dupes, big.mark = ","),
        format(qr$total_na, big.mark = ","),
        format(qr$clean_rows, big.mark = ","),
        format(qr$salary_missing_count, big.mark = ","),
        as.character(qr$clean_cols)
      )
    )
  }, striped = TRUE, bordered = TRUE)

  output$ev_missing_dt <- renderDT({
    na_df <- data.frame(
      Column        = names(qr$na_counts),
      missing_count = as.integer(qr$na_counts),
      missing_pct   = round(as.integer(qr$na_counts) / qr$raw_rows * 100, 1),
      stringsAsFactors = FALSE
    ) |>
      dplyr::filter(missing_count > 0) |>
      dplyr::arrange(dplyr::desc(missing_count)) |>
      dplyr::rename(`Missing Count` = missing_count, `Missing %` = missing_pct)

    datatable(na_df, rownames = FALSE, options = list(pageLength = 8), class = "table table-sm table-hover")
  })

  output$ev_preview_dt <- renderDT({
    preview_sub <- head(df_clean, 300) |>
      dplyr::select(job_id, job_title, company, location, experience_years, education, salary_inr, skills, employment_type, remote_type)
    datatable(preview_sub, rownames = FALSE, options = list(pageLength = 10, scrollX = TRUE), class = "table table-sm table-hover") |>
      formatCurrency("salary_inr", currency = "₹ ", interval = 3, mark = ",", digits = 0)
  })

  output$dl_raw_csv <- downloadHandler(
    filename = function() { "job_market_raw.csv" },
    content = function(file) { file.copy("data/job_market.csv", file) }
  )

  output$dl_clean_csv <- downloadHandler(
    filename = function() { "job_market_clean.csv" },
    content = function(file) { file.copy("data/job_market_clean.csv", file) }
  )
}

# =============================================================================
# 5. RUN APPLICATION
# =============================================================================
shinyApp(ui = ui, server = server)
