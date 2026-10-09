# =============================================================================
# app.R
# CareerLens — Job Market Analysis Dashboard
# ITA04: Statistics with R Programming — College Capstone Project
# -----------------------------------------------------------------------------
# Usage: shiny::runApp()  OR  open in RStudio and click Run App
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

# Source R modules
source("R/helper_functions.R")
source("R/data_cleaning.R")
source("R/skill_analysis.R")
source("R/salary_analysis.R")
source("R/regression_analysis.R")

# ---------------------------------------------------------------------------
# LOAD & CACHE DATA (runs once at startup)
# ---------------------------------------------------------------------------
message("CareerLens: Loading and cleaning data...")
df_clean <- load_and_clean()
qr       <- data_quality_report()
message("Ready. Clean rows: ", nrow(df_clean))

# Pre-compute expensive aggregations once
skill_demand_all <- calculate_skill_demand(df_clean)
all_skills       <- sort(unique(trimws(unlist(strsplit(
  df_clean$skills[!is.na(df_clean$skills)], ";"
)))))
all_skills       <- all_skills[nzchar(all_skills)]

# Run regression models once at startup
slr_result  <- run_simple_regression(df_clean)
mlr_result  <- run_multiple_regression(df_clean)
logit_result <- run_logistic_regression(df_clean)

# ---------------------------------------------------------------------------
# THEME & COLOURS
# ---------------------------------------------------------------------------
app_theme <- bs_theme(
  version   = 5,
  primary   = "#1E6091",
  bg        = "#f8f9fa",
  fg        = "#1a1a1a",
  base_font = font_google("Inter")
)
BLUE  <- "#1E6091"
GREY  <- "#6c757d"
GREEN <- "#198754"
RED   <- "#dc3545"

# ---------------------------------------------------------------------------
# HELPER: ggplot2 base theme for all charts
# ---------------------------------------------------------------------------
theme_careerlens <- function() {
  theme_minimal(base_size=12) +
    theme(
      plot.title        = element_text(size=13, face="bold", color="#1a1a1a", margin=margin(b=8)),
      axis.text         = element_text(color="#444444", size=10),
      axis.title        = element_text(color="#444444", size=11),
      panel.grid.minor  = element_blank(),
      panel.grid.major  = element_line(color="#e9ecef"),
      plot.margin       = margin(10,10,10,10)
    )
}

# ---------------------------------------------------------------------------
# FILTER CHOICES
# ---------------------------------------------------------------------------
choices_location  <- c("All", sort(unique(as.character(df_clean$location))))
choices_title     <- c("All", sort(levels(df_clean$job_title)))
choices_exp       <- c("All", "Fresher (0-1)","Junior (2-3)","Mid (4-6)","Senior (7-10)","Lead (10+)")
choices_industry  <- c("All", sort(levels(df_clean$industry)))
choices_emptype   <- c("All", sort(levels(df_clean$employment_type)))
choices_remote    <- c("All", sort(levels(df_clean$remote_type)))

# ---------------------------------------------------------------------------
# APPLY FILTERS
# ---------------------------------------------------------------------------
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

# ===========================================================================
# UI
# ===========================================================================
ui <- page_navbar(
  title = tags$span(
    tags$img(src="", style="display:none"),
    tags$strong("CareerLens"),
    tags$span(" | Job Market Analysis", style="font-weight:300; color:#a8c8e8; font-size:0.9em;")
  ),
  theme    = app_theme,
  id       = "nav",
  selected = "Overview",
  header   = tags$head(
    tags$link(rel="stylesheet", href="styles.css")
  ),

  # ---- TAB 1: OVERVIEW ----
  nav_panel("Overview",
    layout_sidebar(
      sidebar = sidebar(
        width = 220,
        tags$p(tags$strong("Filters"), class="sidebar-heading"),
        selectInput("ov_location", "Location",   choices=choices_location),
        selectInput("ov_title",    "Job Role",   choices=choices_title),
        selectInput("ov_exp",      "Experience", choices=choices_exp),
        selectInput("ov_industry", "Industry",   choices=choices_industry),
        selectInput("ov_emptype",  "Employment", choices=choices_emptype),
        selectInput("ov_remote",   "Remote Type",choices=choices_remote),
        actionButton("ov_reset", "Reset Filters", class="btn btn-sm btn-outline-secondary w-100 mt-2")
      ),
      # KPI row
      fluidRow(
        column(2, div(class="kpi-card",
          tags$p("Total Postings", class="kpi-label"),
          tags$h3(textOutput("kpi_total"), class="kpi-value")
        )),
        column(2, div(class="kpi-card",
          tags$p("Avg Salary", class="kpi-label"),
          tags$h3(textOutput("kpi_avg_sal"), class="kpi-value")
        )),
        column(2, div(class="kpi-card",
          tags$p("Median Salary", class="kpi-label"),
          tags$h3(textOutput("kpi_med_sal"), class="kpi-value")
        )),
        column(2, div(class="kpi-card",
          tags$p("Top Skill", class="kpi-label"),
          tags$h3(textOutput("kpi_top_skill"), class="kpi-value kpi-sm")
        )),
        column(2, div(class="kpi-card",
          tags$p("Top Role", class="kpi-label"),
          tags$h3(textOutput("kpi_top_role"), class="kpi-value kpi-sm")
        )),
        column(2, div(class="kpi-card",
          tags$p("Top Location", class="kpi-label"),
          tags$h3(textOutput("kpi_top_loc"), class="kpi-value kpi-sm")
        ))
      ),
      tags$hr(),
      fluidRow(
        column(6, card(card_header("Job Postings by Role"),     plotlyOutput("ov_role_bar",   height=320))),
        column(6, card(card_header("Job Postings by Location"), plotlyOutput("ov_loc_bar",    height=320)))
      ),
      fluidRow(
        column(4, card(card_header("Experience Distribution"),    plotlyOutput("ov_exp_hist",   height=260))),
        column(4, card(card_header("Employment Type"),            plotlyOutput("ov_emp_pie",    height=260))),
        column(4, card(card_header("Salary Distribution (₹L)"),  plotlyOutput("ov_sal_hist",   height=260)))
      )
    )
  ),

  # ---- TAB 2: SKILLS DEMAND ----
  nav_panel("Skills Demand",
    layout_sidebar(
      sidebar = sidebar(
        width=220,
        selectInput("sk_role",     "Job Role",   choices=choices_title),
        selectInput("sk_location", "Location",   choices=choices_location)
      ),
      fluidRow(
        column(7, card(card_header("Top 20 In-Demand Skills"),
          plotlyOutput("sk_top20_bar", height=400)
        )),
        column(5, card(card_header("Skill Categories Breakdown"),
          plotlyOutput("sk_category_pie", height=400)
        ))
      ),
      fluidRow(
        column(6, card(card_header("Role-Specific Skill Demand"),
          plotlyOutput("sk_role_bar", height=320)
        )),
        column(6, card(card_header("Location-Specific Skill Demand"),
          plotlyOutput("sk_loc_bar", height=320)
        ))
      ),
      card(card_header("Skill Demand Table — Rank | Skill | Job Count | Demand %"),
        DTOutput("sk_table")
      )
    )
  ),

  # ---- TAB 3: SALARY & LOCATION ----
  nav_panel("Salary & Location",
    layout_sidebar(
      sidebar=sidebar(
        width=220,
        selectInput("sl_role",    "Job Role",    choices=choices_title),
        selectInput("sl_loc",     "Location",    choices=choices_location),
        selectInput("sl_emptype", "Employment",  choices=choices_emptype)
      ),
      fluidRow(
        column(12, card(card_header("Salary Descriptive Statistics"),
          tableOutput("sl_stats_table")
        ))
      ),
      fluidRow(
        column(6, card(card_header("Salary Distribution (₹ Lakhs)"),
          plotlyOutput("sl_hist", height=280)
        )),
        column(6, card(card_header("Salary by Employment Type"),
          plotlyOutput("sl_boxplot", height=280)
        ))
      ),
      fluidRow(
        column(6, card(card_header("Average Salary by Job Role"),
          plotlyOutput("sl_role_bar", height=320)
        )),
        column(6, card(card_header("Average Salary by Location"),
          plotlyOutput("sl_loc_bar", height=320)
        ))
      ),
      fluidRow(
        column(12, card(card_header("Salary by Experience Level"),
          plotlyOutput("sl_exp_bar", height=260)
        ))
      )
    )
  ),

  # ---- TAB 4: STATISTICS & CORRELATION ----
  nav_panel("Statistics & Correlation",
    fluidRow(
      column(7, card(card_header("Correlation Matrix — Pearson Coefficients"),
        plotOutput("cor_heatmap", height=420)
      )),
      column(5,
        card(card_header("Correlation Coefficients"),
          tableOutput("cor_table")
        ),
        card(card_header("Interpretation"),
          uiOutput("cor_interpretation")
        )
      )
    ),
    fluidRow(
      column(12, card(card_header("Experience vs Salary Scatter"),
        plotlyOutput("cor_scatter", height=300)
      ))
    )
  ),

  # ---- TAB 5: REGRESSION & PREDICTION ----
  nav_panel("Regression & Prediction",
    navset_card_tab(
      nav_panel("A. Simple Linear Regression",
        fluidRow(
          column(5,
            card(card_header("Model Summary"),
              tags$table(class="table table-sm table-bordered",
                tags$tbody(
                  tags$tr(tags$th("Model"),     tags$td("salary_inr ~ experience_years")),
                  tags$tr(tags$th("Equation"),  tags$td(textOutput("slr_equation"))),
                  tags$tr(tags$th("Intercept"), tags$td(textOutput("slr_intercept"))),
                  tags$tr(tags$th("Slope"),     tags$td(textOutput("slr_slope"))),
                  tags$tr(tags$th("R²"),        tags$td(textOutput("slr_rsq"))),
                  tags$tr(tags$th("p-value"),   tags$td(textOutput("slr_pval")))
                )
              )
            ),
            card(card_header("Coefficient Table"),
              tableOutput("slr_coef_table")
            )
          ),
          column(7, card(card_header("Scatter Plot with Regression Line"),
            plotlyOutput("slr_scatter", height=380)
          ))
        )
      ),

      nav_panel("B. Multiple Linear Regression",
        fluidRow(
          column(5,
            card(card_header("Model Summary"),
              tags$table(class="table table-sm table-bordered",
                tags$tbody(
                  tags$tr(tags$th("Model"),         tags$td("salary_inr ~ experience + skill_count + education + company_size + location_tier")),
                  tags$tr(tags$th("R²"),            tags$td(textOutput("mlr_rsq"))),
                  tags$tr(tags$th("Adjusted R²"),   tags$td(textOutput("mlr_adj_rsq"))),
                  tags$tr(tags$th("F-statistic"),   tags$td(textOutput("mlr_fstat"))),
                  tags$tr(tags$th("p-value"),       tags$td(textOutput("mlr_pval")))
                )
              )
            ),
            card(card_header("Coefficients"),
              DTOutput("mlr_coef_table")
            )
          ),
          column(7, card(card_header("Actual vs Predicted Salary"),
            plotlyOutput("mlr_scatter", height=380)
          ))
        )
      ),

      nav_panel("C. Logistic Regression & Prediction",
        fluidRow(
          column(5,
            card(card_header("Logistic Regression — High Salary Prediction"),
              tags$p(class="text-muted small",
                "High Salary = 1 if salary ≥ median. Threshold: ", textOutput("logit_threshold", inline=TRUE)
              ),
              card(card_header("Model Accuracy"),
                tableOutput("logit_cm_table")
              ),
              card(card_header("Coefficients"),
                DTOutput("logit_coef")
              )
            )
          ),
          column(7,
            card(card_header("Prediction Tool"),
              tags$p(class="text-muted small",
                "Enter candidate profile to estimate salary and high-salary probability."
              ),
              fluidRow(
                column(6,
                  sliderInput("pred_exp",   "Experience (years)", min=0, max=20, value=3, step=1),
                  sliderInput("pred_skills","Skill Count",        min=1, max=20, value=6, step=1)
                ),
                column(6,
                  selectInput("pred_edu",  "Education",
                    choices=levels(df_clean$education)),
                  selectInput("pred_size", "Company Size",
                    choices=c("Small","Medium","Large","Enterprise"))
                )
              ),
              actionButton("btn_predict", "Calculate Prediction", class="btn btn-primary"),
              tags$hr(),
              uiOutput("prediction_output"),
              tags$p(class="text-muted small mt-2",
                tags$em("These are statistical estimates derived from the training dataset and should not be treated as guarantees.")
              )
            )
          )
        )
      )
    )
  ),

  # ---- TAB 6: SKILL GAP ANALYZER ----
  nav_panel("Skill Gap Analyzer",
    fluidRow(
      column(4,
        card(card_header("Your Profile"),
          selectizeInput(
            "gap_skills", "Your Current Skills",
            choices  = all_skills,
            multiple = TRUE,
            options  = list(placeholder="Type or select skills...")
          ),
          selectInput(
            "gap_role", "Desired Job Role",
            choices = sort(levels(df_clean$job_title))
          ),
          actionButton("btn_gap", "Analyse Skill Gap", class="btn btn-primary w-100 mt-2")
        )
      ),
      column(8,
        uiOutput("gap_summary_cards"),
        card(card_header("Skill Gap Analysis — Matched & Missing Skills"),
          DTOutput("gap_table")
        ),
        card(card_header("Missing Skills by Market Demand (%)"),
          plotlyOutput("gap_bar", height=300)
        ),
        uiOutput("gap_recommendations")
      )
    )
  ),

  # ---- TAB 7: DATA QUALITY / DATASET ----
  nav_panel("Data Quality",
    fluidRow(
      column(6, card(card_header("Data Quality Summary"),
        tableOutput("dq_summary")
      )),
      column(6, card(card_header("Missing Values per Column"),
        DTOutput("dq_missing")
      ))
    ),
    card(card_header("Clean Dataset Preview (first 300 rows)"),
      DTOutput("dq_preview")
    ),
    fluidRow(
      column(6, downloadButton("dl_raw",   "Download Raw Dataset",   class="btn btn-outline-secondary")),
      column(6, downloadButton("dl_clean", "Download Clean Dataset", class="btn btn-outline-primary"))
    )
  )
)  # end page_navbar


# ===========================================================================
# SERVER
# ===========================================================================
server <- function(input, output, session) {

  # ---- Reactive: filtered data ----
  df_filtered <- reactive({
    apply_filters(
      df_clean,
      location  = input$ov_location,
      title     = input$ov_title,
      exp_level = input$ov_exp,
      industry  = input$ov_industry,
      emp_type  = input$ov_emptype,
      remote    = input$ov_remote
    )
  })

  # Reset filters
  observeEvent(input$ov_reset, {
    updateSelectInput(session, "ov_location", selected="All")
    updateSelectInput(session, "ov_title",    selected="All")
    updateSelectInput(session, "ov_exp",      selected="All")
    updateSelectInput(session, "ov_industry", selected="All")
    updateSelectInput(session, "ov_emptype",  selected="All")
    updateSelectInput(session, "ov_remote",   selected="All")
  })

  no_data_msg <- function(msg="No records match the selected filters.") {
    plotly_empty() |> layout(title=list(text=msg, font=list(color=GREY)))
  }

  # ------------------------------------------------------------------
  # TAB 1 — OVERVIEW
  # ------------------------------------------------------------------
  output$kpi_total     <- renderText({ format(nrow(df_filtered()), big.mark=",") })
  output$kpi_avg_sal   <- renderText({ format_inr(safe_mean(df_filtered()$salary_inr)) })
  output$kpi_med_sal   <- renderText({ format_inr(safe_median(df_filtered()$salary_inr)) })
  output$kpi_top_skill <- renderText({
    df <- df_filtered()
    if (nrow(df)==0) return("—")
    sk <- calculate_skill_demand(df)
    if (nrow(sk)==0) return("—")
    as.character(sk$skill[1])
  })
  output$kpi_top_role <- renderText({
    df <- df_filtered()
    if (nrow(df)==0) return("—")
    tbl <- sort(table(df$job_title), decreasing=TRUE)
    names(tbl)[1]
  })
  output$kpi_top_loc  <- renderText({
    df <- df_filtered()
    if (nrow(df)==0) return("—")
    tbl <- sort(table(df$location), decreasing=TRUE)
    names(tbl)[1]
  })

  output$ov_role_bar <- renderPlotly({
    df <- df_filtered()
    if (nrow(df)==0) return(no_data_msg())
    tbl <- df |> dplyr::count(job_title, name="n") |>
      dplyr::arrange(dplyr::desc(n)) |> dplyr::slice_head(n=15)
    plot_ly(tbl, x=~n, y=~reorder(job_title, n), type="bar", orientation="h",
            marker=list(color=BLUE)) |>
      layout(
        xaxis=list(title="Job Count"), yaxis=list(title=""),
        margin=list(l=160), paper_bgcolor="white", plot_bgcolor="white"
      )
  })

  output$ov_loc_bar <- renderPlotly({
    df <- df_filtered()
    if (nrow(df)==0) return(no_data_msg())
    tbl <- df |> dplyr::count(location, name="n") |>
      dplyr::arrange(dplyr::desc(n)) |> dplyr::slice_head(n=15)
    plot_ly(tbl, x=~n, y=~reorder(location, n), type="bar", orientation="h",
            marker=list(color="#2e86ab")) |>
      layout(
        xaxis=list(title="Job Count"), yaxis=list(title=""),
        margin=list(l=130), paper_bgcolor="white", plot_bgcolor="white"
      )
  })

  output$ov_exp_hist <- renderPlotly({
    df <- df_filtered()
    if (nrow(df)==0) return(no_data_msg())
    plot_ly(df, x=~experience_years, type="histogram",
            marker=list(color=BLUE, line=list(color="white", width=0.5))) |>
      layout(
        xaxis=list(title="Years of Experience"), yaxis=list(title="Count"),
        paper_bgcolor="white", plot_bgcolor="white"
      )
  })

  output$ov_emp_pie <- renderPlotly({
    df <- df_filtered()
    if (nrow(df)==0) return(no_data_msg())
    tbl <- df |> dplyr::count(employment_type, name="n")
    plot_ly(tbl, labels=~employment_type, values=~n, type="pie",
            textposition="inside", textinfo="label+percent",
            marker=list(colors=c(BLUE,"#2e86ab","#a8c8e8","#d4e8f5"))) |>
      layout(showlegend=FALSE, paper_bgcolor="white")
  })

  output$ov_sal_hist <- renderPlotly({
    df <- df_filtered()
    sal_l <- df$salary_inr[!is.na(df$salary_inr)] / 1e5
    if (length(sal_l)==0) return(no_data_msg())
    plot_ly(x=sal_l, type="histogram",
            marker=list(color=BLUE, line=list(color="white", width=0.5))) |>
      layout(
        xaxis=list(title="Salary (₹ Lakhs)"), yaxis=list(title="Count"),
        paper_bgcolor="white", plot_bgcolor="white"
      )
  })

  # ------------------------------------------------------------------
  # TAB 2 — SKILLS DEMAND
  # ------------------------------------------------------------------
  output$sk_top20_bar <- renderPlotly({
    top20 <- skill_demand_all |> dplyr::slice_head(n=20)
    plot_ly(top20, x=~demand_pct, y=~reorder(skill, demand_pct),
            type="bar", orientation="h",
            text=~paste0(demand_pct,"%"), textposition="outside",
            marker=list(color=BLUE)) |>
      layout(
        xaxis=list(title="Demand (% of jobs)", range=c(0, max(top20$demand_pct)*1.15)),
        yaxis=list(title=""), margin=list(l=130),
        paper_bgcolor="white", plot_bgcolor="white"
      )
  })

  output$sk_category_pie <- renderPlotly({
    cat_tbl <- skill_demand_all |>
      dplyr::group_by(skill_category) |>
      dplyr::summarise(total=sum(job_count), .groups="drop") |>
      dplyr::arrange(dplyr::desc(total))
    plot_ly(cat_tbl, labels=~skill_category, values=~total, type="pie",
            textposition="inside", textinfo="label+percent") |>
      layout(showlegend=TRUE, paper_bgcolor="white")
  })

  output$sk_role_bar <- renderPlotly({
    role <- if (input$sk_role == "All") levels(df_clean$job_title)[1] else input$sk_role
    tbl  <- role_skill_demand(df_clean, role, top_n=12)
    if (nrow(tbl)==0) return(no_data_msg("No skill data for this role."))
    plot_ly(tbl, x=~demand_pct, y=~reorder(skill, demand_pct),
            type="bar", orientation="h",
            marker=list(color="#2e86ab")) |>
      layout(
        title=list(text=paste("Skills for:", role), font=list(size=12)),
        xaxis=list(title="Demand %"), yaxis=list(title=""),
        margin=list(l=130), paper_bgcolor="white", plot_bgcolor="white"
      )
  })

  output$sk_loc_bar <- renderPlotly({
    loc <- if (input$sk_location == "All") "Bengaluru" else input$sk_location
    tbl <- location_skill_demand(df_clean, loc, top_n=12)
    if (nrow(tbl)==0) return(no_data_msg("No skill data for this location."))
    plot_ly(tbl, x=~demand_pct, y=~reorder(skill, demand_pct),
            type="bar", orientation="h",
            marker=list(color="#5a9e6f")) |>
      layout(
        title=list(text=paste("Skills in:", loc), font=list(size=12)),
        xaxis=list(title="Demand %"), yaxis=list(title=""),
        margin=list(l=130), paper_bgcolor="white", plot_bgcolor="white"
      )
  })

  output$sk_table <- renderDT({
    skill_demand_all |>
      dplyr::select(Rank=rank, Skill=skill, Category=skill_category,
                    `Job Count`=job_count, `Demand %`=demand_pct) |>
      DT::datatable(
        options=list(pageLength=15, order=list(list(0,"asc"))),
        rownames=FALSE, class="table table-sm table-hover"
      )
  })

  # ------------------------------------------------------------------
  # TAB 3 — SALARY & LOCATION
  # ------------------------------------------------------------------
  df_sal_filtered <- reactive({
    df <- df_clean
    if (input$sl_role    != "All") df <- df[as.character(df$job_title) == input$sl_role, ]
    if (input$sl_loc     != "All") df <- df[df$location == input$sl_loc, ]
    if (input$sl_emptype != "All") df <- df[as.character(df$employment_type) == input$sl_emptype, ]
    df
  })

  output$sl_stats_table <- renderTable({
    s <- calculate_salary_summary(df_sal_filtered())
    if (length(s) == 0) return(data.frame(Message="No data for selected filters"))
    data.frame(
      Statistic = c("Count","Mean","Median","Mode (bucket)","Minimum","Maximum",
                    "Range","Variance","Std Deviation","Q1 (25th)","Q3 (75th)",
                    "IQR","10th Percentile","90th Percentile","CV (%)"),
      Value = c(
        format(s$n, big.mark=","),
        format_inr(s$mean), format_inr(s$median), format_inr(s$mode),
        format_inr(s$min),  format_inr(s$max),    format_inr(s$range),
        format_inr(s$variance), format_inr(s$sd),
        format_inr(s$q1),   format_inr(s$q3),    format_inr(s$iqr),
        format_inr(s$p10),  format_inr(s$p90),
        paste0(s$cv_pct, "%")
      )
    )
  }, striped=TRUE, bordered=TRUE, hover=TRUE, spacing="xs")

  output$sl_hist <- renderPlotly({
    df <- df_sal_filtered()
    sal_l <- df$salary_inr[!is.na(df$salary_inr)] / 1e5
    if (length(sal_l)==0) return(no_data_msg())
    plot_ly(x=sal_l, type="histogram",
            marker=list(color=BLUE, line=list(color="white", width=0.4))) |>
      layout(
        xaxis=list(title="Annual Salary (₹ Lakhs)"), yaxis=list(title="Count"),
        paper_bgcolor="white", plot_bgcolor="white"
      )
  })

  output$sl_boxplot <- renderPlotly({
    df <- df_sal_filtered()
    if (nrow(df)==0) return(no_data_msg())
    plot_ly(df, x=~as.character(employment_type), y=~salary_inr/1e5,
            type="box", fillcolor=BLUE,
            line=list(color=BLUE)) |>
      layout(
        xaxis=list(title="Employment Type"), yaxis=list(title="Salary (₹ Lakhs)"),
        paper_bgcolor="white", plot_bgcolor="white"
      )
  })

  output$sl_role_bar <- renderPlotly({
    df <- df_sal_filtered()
    tbl <- salary_by_role(df, top_n=15)
    if (nrow(tbl)==0) return(no_data_msg())
    plot_ly(tbl, x=~mean_salary/1e5, y=~reorder(job_title, mean_salary),
            type="bar", orientation="h",
            text=~paste0("Avg: ", format_inr(mean_salary), "<br>Median: ", format_inr(median_salary)),
            hoverinfo="text",
            marker=list(color=BLUE)) |>
      layout(
        xaxis=list(title="Mean Salary (₹ Lakhs)"), yaxis=list(title=""),
        margin=list(l=160), paper_bgcolor="white", plot_bgcolor="white"
      )
  })

  output$sl_loc_bar <- renderPlotly({
    df <- df_sal_filtered()
    tbl <- salary_by_location(df, top_n=15)
    if (nrow(tbl)==0) return(no_data_msg())
    plot_ly(tbl, x=~mean_salary/1e5, y=~reorder(location, mean_salary),
            type="bar", orientation="h",
            text=~paste0(location, ": ", format_inr(mean_salary)),
            hoverinfo="text",
            marker=list(color="#2e86ab")) |>
      layout(
        xaxis=list(title="Mean Salary (₹ Lakhs)"), yaxis=list(title=""),
        margin=list(l=130), paper_bgcolor="white", plot_bgcolor="white"
      )
  })

  output$sl_exp_bar <- renderPlotly({
    tbl <- salary_by_experience(df_clean)
    if (nrow(tbl)==0) return(no_data_msg())
    plot_ly(tbl, x=~as.character(experience_bin), y=~mean_salary/1e5,
            type="bar",
            text=~paste0(format_inr(mean_salary)), hoverinfo="text",
            marker=list(color=BLUE)) |>
      layout(
        xaxis=list(title="Experience Level"), yaxis=list(title="Mean Salary (₹ Lakhs)"),
        paper_bgcolor="white", plot_bgcolor="white"
      )
  })

  # ------------------------------------------------------------------
  # TAB 4 — STATISTICS & CORRELATION
  # ------------------------------------------------------------------
  cor_data <- reactive({
    df_clean |>
      dplyr::select(
        experience_years, salary_inr, skill_count, company_size_num
      ) |>
      dplyr::filter(dplyr::if_all(everything(), ~!is.na(.x))) |>
      dplyr::rename(
        `Exp. Years`   = experience_years,
        `Salary (INR)` = salary_inr,
        `Skill Count`  = skill_count,
        `Co. Size`     = company_size_num
      )
  })

  output$cor_heatmap <- renderPlot({
    cm <- cor(cor_data(), method="pearson")
    corrplot::corrplot(
      cm, method="color", type="upper",
      addCoef.col="black", number.cex=0.85,
      tl.col="black", tl.srt=30, tl.cex=0.9,
      col=colorRampPalette(c("#dc3545","white","#1E6091"))(200),
      mar=c(0,0,1,0)
    )
  })

  output$cor_table <- renderTable({
    cm <- cor(cor_data(), method="pearson")
    df_ct <- as.data.frame(round(cm, 3))
    df_ct <- cbind(Variable=rownames(df_ct), df_ct)
    df_ct
  }, striped=TRUE, bordered=TRUE, hover=TRUE, spacing="xs")

  output$cor_interpretation <- renderUI({
    cm     <- cor(cor_data(), method="pearson")
    r_es   <- cm["Exp. Years", "Salary (INR)"]
    r_sk   <- cm["Skill Count","Salary (INR)"]
    r_esc  <- cm["Exp. Years", "Skill Count"]

    tagList(
      tags$p(tags$strong("Experience vs Salary: "),
        sprintf("r = %.3f (%s correlation)", r_es, stat_label(r_es))),
      tags$p(tags$strong("Skill Count vs Salary: "),
        sprintf("r = %.3f (%s correlation)", r_sk, stat_label(r_sk))),
      tags$p(tags$strong("Experience vs Skill Count: "),
        sprintf("r = %.3f (%s correlation)", r_esc, stat_label(r_esc))),
      tags$hr(),
      tags$p(class="text-muted small",
        "Pearson correlation (r) measures linear association between two variables.",
        "r = +1 indicates perfect positive correlation; r = -1 perfect negative; r = 0 indicates no linear relationship.")
    )
  })

  output$cor_scatter <- renderPlotly({
    df_s <- df_clean |> dplyr::filter(!is.na(salary_inr), !is.na(experience_years))
    plot_ly(df_s, x=~experience_years, y=~salary_inr/1e5,
            type="scatter", mode="markers",
            marker=list(color=BLUE, size=4, opacity=0.35),
            hovertemplate="Exp: %{x} yrs<br>Salary: ₹%{y:.1f}L<extra></extra>") |>
      add_lines(
        x=~experience_years,
        y=~predict(lm(salary_inr/1e5 ~ experience_years, data=df_s)),
        line=list(color=RED, width=2), name="Regression Line"
      ) |>
      layout(
        xaxis=list(title="Experience (Years)"),
        yaxis=list(title="Salary (₹ Lakhs)"),
        paper_bgcolor="white", plot_bgcolor="white",
        showlegend=FALSE
      )
  })

  # ------------------------------------------------------------------
  # TAB 5 — REGRESSION & PREDICTION
  # ------------------------------------------------------------------

  # Simple LR
  output$slr_equation   <- renderText({ slr_result$equation })
  output$slr_intercept  <- renderText({ format(round(slr_result$intercept), big.mark=",") })
  output$slr_slope      <- renderText({ format(round(slr_result$slope), big.mark=",") })
  output$slr_rsq        <- renderText({ round(slr_result$r_squared, 4) })
  output$slr_pval       <- renderText({
    p <- slr_result$p_value
    if (p < 0.001) "< 0.001 (***)" else round(p, 4)
  })
  output$slr_coef_table <- renderTable({
    ct <- slr_result$coef_table
    ct <- cbind(Term=rownames(ct), round(ct, 4))
    colnames(ct) <- c("Term","Estimate","Std Error","t value","Pr(>|t|)")
    ct
  }, striped=TRUE, bordered=TRUE, hover=TRUE)

  output$slr_scatter <- renderPlotly({
    df_m <- slr_result$data
    df_m$predicted <- predict(slr_result$model)
    plot_ly() |>
      add_trace(data=df_m, x=~experience_years, y=~salary_inr/1e5,
                type="scatter", mode="markers",
                marker=list(color=BLUE, size=4, opacity=0.3), name="Actual") |>
      add_trace(data=df_m, x=~experience_years, y=~predicted/1e5,
                type="scatter", mode="lines",
                line=list(color=RED, width=2), name="Regression Line") |>
      layout(
        xaxis=list(title="Experience (Years)"),
        yaxis=list(title="Salary (₹ Lakhs)"),
        paper_bgcolor="white", plot_bgcolor="white"
      )
  })

  # Multiple LR
  output$mlr_rsq     <- renderText({ round(mlr_result$r_squared, 4) })
  output$mlr_adj_rsq <- renderText({ round(mlr_result$adj_r_sq,  4) })
  output$mlr_fstat   <- renderText({ round(mlr_result$f_stat,    2) })
  output$mlr_pval    <- renderText({
    p <- mlr_result$p_value
    if (p < 0.001) "< 0.001 (***)" else round(p, 6)
  })
  output$mlr_coef_table <- renderDT({
    ct <- mlr_result$coef_table
    ct <- cbind(Term=rownames(ct), round(ct, 4))
    colnames(ct) <- c("Term","Estimate","Std Error","t value","Pr(>|t|)")
    DT::datatable(ct, rownames=FALSE, options=list(pageLength=10, scrollX=TRUE),
                  class="table table-sm table-hover")
  })
  output$mlr_scatter <- renderPlotly({
    df_m       <- mlr_result$data
    df_m$pred  <- predict(mlr_result$model)
    plot_ly(df_m, x=~salary_inr/1e5, y=~pred/1e5,
            type="scatter", mode="markers",
            marker=list(color=BLUE, size=4, opacity=0.3),
            hovertemplate="Actual: ₹%{x:.1f}L<br>Predicted: ₹%{y:.1f}L<extra></extra>") |>
      add_trace(x=range(df_m$salary_inr/1e5), y=range(df_m$salary_inr/1e5),
                type="scatter", mode="lines",
                line=list(color=RED, dash="dash", width=1.5), name="Perfect Fit") |>
      layout(
        xaxis=list(title="Actual Salary (₹ Lakhs)"),
        yaxis=list(title="Predicted Salary (₹ Lakhs)"),
        paper_bgcolor="white", plot_bgcolor="white"
      )
  })

  # Logistic Regression
  output$logit_threshold <- renderText({ format_inr(logit_result$threshold) })
  output$logit_coef      <- renderDT({
    ct <- logit_result$coef_table
    ct <- cbind(Term=rownames(ct), round(ct, 4))
    colnames(ct) <- c("Term","Estimate","Std Error","z value","Pr(>|z|)")
    DT::datatable(ct, rownames=FALSE, options=list(pageLength=8, scrollX=TRUE),
                  class="table table-sm")
  })
  output$logit_cm_table <- renderTable({
    cms <- logit_result$cm_summary
    data.frame(
      Metric    = c("Accuracy", "Sensitivity (Recall)", "Specificity"),
      Value     = paste0(c(cms$accuracy, cms$sensitivity, cms$specificity), "%")
    )
  }, striped=TRUE, bordered=TRUE)

  # Prediction
  prediction_rv <- reactiveVal(NULL)
  observeEvent(input$btn_predict, {
    sal  <- predict_salary(slr_result, input$pred_exp)
    prob <- predict_high_salary_prob(
      logit_result,
      experience_years = input$pred_exp,
      skill_count      = input$pred_skills,
      education        = input$pred_edu,
      company_size     = input$pred_size
    )
    prediction_rv(list(sal=sal, prob=prob))
  })

  output$prediction_output <- renderUI({
    p <- prediction_rv()
    if (is.null(p)) return(tags$p(class="text-muted", "Click 'Calculate Prediction' to see results."))
    sal_fmt  <- format_inr(p$sal$estimate)
    sal_low  <- format_inr(max(p$sal$lower, 0))
    sal_high <- format_inr(p$sal$upper)
    prob_val <- p$prob$probability
    cls      <- p$prob$predicted
    cls_col  <- if (grepl("High", cls)) GREEN else GREY

    tagList(
      fluidRow(
        column(6, div(class="pred-result-box",
          tags$p("Estimated Annual Salary", class="kpi-label"),
          tags$h3(sal_fmt, class="kpi-value"),
          tags$p(paste0("Range: ", sal_low, " — ", sal_high), class="text-muted small")
        )),
        column(6, div(class="pred-result-box",
          tags$p("High Salary Probability", class="kpi-label"),
          tags$h3(paste0(prob_val, "%"), class="kpi-value",
                  style=paste0("color:", cls_col)),
          tags$p(cls, class="small", style=paste0("color:", cls_col, "; font-weight:500;"))
        ))
      )
    )
  })

  # ------------------------------------------------------------------
  # TAB 6 — SKILL GAP ANALYZER
  # ------------------------------------------------------------------
  gap_rv <- reactiveVal(NULL)

  observeEvent(input$btn_gap, {
    candidate_skills <- input$gap_skills
    target_role      <- input$gap_role

    if (length(candidate_skills) == 0) {
      showNotification("Please select at least one skill.", type="warning")
      return()
    }

    role_skills <- role_skill_demand(df_clean, target_role, top_n=30)
    if (nrow(role_skills) == 0) {
      showNotification("No skill data for the selected role.", type="warning")
      return()
    }

    candidate_upper <- toupper(trimws(candidate_skills))
    role_skills$status <- ifelse(
      toupper(role_skills$skill) %in% candidate_upper, "Matched", "Missing"
    )
    gap_rv(list(tbl=role_skills, candidate=candidate_skills, role=target_role))
  })

  output$gap_summary_cards <- renderUI({
    g <- gap_rv()
    if (is.null(g)) return(tags$p(class="text-muted mt-2",
      "Configure your profile on the left and click 'Analyse Skill Gap'."))
    matched <- sum(g$tbl$status == "Matched")
    missing <- sum(g$tbl$status == "Missing")
    total   <- nrow(g$tbl)
    gap_pct <- round(missing / total * 100)
    role_count <- nrow(df_clean[as.character(df_clean$job_title)==g$role,])

    fluidRow(
      column(3, div(class="kpi-card",
        tags$p("Target Role", class="kpi-label"),
        tags$h4(g$role, class="kpi-value kpi-sm")
      )),
      column(3, div(class="kpi-card",
        tags$p("Matched Skills", class="kpi-label"),
        tags$h3(matched, class="kpi-value", style=paste0("color:", GREEN))
      )),
      column(3, div(class="kpi-card",
        tags$p("Missing Skills", class="kpi-label"),
        tags$h3(missing, class="kpi-value", style=paste0("color:", RED))
      )),
      column(3, div(class="kpi-card",
        tags$p("Gap Score", class="kpi-label"),
        tags$h3(paste0(gap_pct, "%"), class="kpi-value", style=paste0("color:", GREY))
      ))
    )
  })

  output$gap_table <- renderDT({
    g <- gap_rv()
    if (is.null(g)) return(DT::datatable(data.frame()))
    tbl_display <- g$tbl |>
      dplyr::mutate(
        Status = dplyr::case_when(
          status == "Matched" ~ "\u2713 Matched",
          TRUE                ~ "\u2717 Missing"
        ),
        `Market Demand %` = demand_pct
      ) |>
      dplyr::select(Skill=skill, Status, `Market Demand %`, Category=skill_category) |>
      dplyr::arrange(dplyr::desc(`Market Demand %`))

    DT::datatable(
      tbl_display, rownames=FALSE,
      options=list(pageLength=15, dom="t"),
      class="table table-sm table-hover"
    ) |>
      DT::formatStyle(
        "Status",
        color=DT::styleEqual(c("\u2713 Matched","\u2717 Missing"), c(GREEN, RED)),
        fontWeight="bold"
      )
  })

  output$gap_bar <- renderPlotly({
    g <- gap_rv()
    if (is.null(g)) return(plotly_empty())
    missing_tbl <- g$tbl |> dplyr::filter(status=="Missing") |>
      dplyr::arrange(dplyr::desc(demand_pct)) |> dplyr::slice_head(n=10)
    if (nrow(missing_tbl)==0) {
      return(plotly_empty() |> layout(title="No missing skills — your profile is a strong match!"))
    }
    plot_ly(missing_tbl, x=~demand_pct, y=~reorder(skill, demand_pct),
            type="bar", orientation="h",
            marker=list(color=RED)) |>
      layout(
        xaxis=list(title="Market Demand (%)"), yaxis=list(title=""),
        margin=list(l=130), paper_bgcolor="white", plot_bgcolor="white"
      )
  })

  output$gap_recommendations <- renderUI({
    g <- gap_rv()
    if (is.null(g)) return(NULL)
    missing_tbl <- g$tbl |> dplyr::filter(status=="Missing") |>
      dplyr::arrange(dplyr::desc(demand_pct)) |> dplyr::slice_head(n=5)
    if (nrow(missing_tbl)==0) {
      return(card(card_header("Recommendation"),
        tags$p(class="text-success", tags$strong("\u2713 Excellent match!"),
          " Your skills align well with the target role requirements.")))
    }
    rows <- lapply(seq_len(nrow(missing_tbl)), function(i) {
      tags$li(
        tags$strong(missing_tbl$skill[i]),
        sprintf(" — %.1f%% of %s jobs require this skill.",
                missing_tbl$demand_pct[i], g$role)
      )
    })
    card(card_header("Recommended Skills to Learn"),
      tags$p(class="text-muted small",
        "Based on actual market demand from the dataset. Sorted by demand %."),
      tags$ol(rows)
    )
  })

  # ------------------------------------------------------------------
  # TAB 7 — DATA QUALITY
  # ------------------------------------------------------------------
  output$dq_summary <- renderTable({
    data.frame(
      Metric  = c("Raw Records","Duplicate Records Removed","Total Missing Values",
                  "Clean Records","Raw Columns","Clean Columns"),
      Value   = c(
        format(qr$raw_rows,   big.mark=","),
        format(qr$n_dupes,    big.mark=","),
        format(qr$total_na,   big.mark=","),
        format(qr$clean_rows, big.mark=","),
        qr$raw_cols,
        qr$clean_cols
      )
    )
  }, striped=TRUE, bordered=TRUE, hover=TRUE)

  output$dq_missing <- renderDT({
    na_df <- data.frame(
      Column        = names(qr$na_counts),
      missing_count = as.integer(qr$na_counts),
      missing_pct   = round(as.integer(qr$na_counts) / qr$raw_rows * 100, 1),
      stringsAsFactors = FALSE
    ) |>
      dplyr::filter(missing_count > 0) |>
      dplyr::arrange(dplyr::desc(missing_count)) |>
      dplyr::rename(
        `Missing Count` = missing_count,
        `Missing %`     = missing_pct
      )
    DT::datatable(na_df, rownames=FALSE, options=list(pageLength=10),
                  class="table table-sm table-hover")
  })

  output$dq_preview <- renderDT({
    df_show <- df_clean |>
      dplyr::select(job_id, job_title, company, location, experience_years,
                    education, salary_inr, skills, employment_type, remote_type) |>
      dplyr::slice_head(n=300)
    DT::datatable(
      df_show, rownames=FALSE,
      options=list(pageLength=15, scrollX=TRUE),
      class="table table-sm table-hover"
    )
  })

  output$dl_raw <- downloadHandler(
    filename = "job_market_raw.csv",
    content  = function(f) readr::write_csv(readr::read_csv("data/job_market.csv", show_col_types=FALSE), f)
  )
  output$dl_clean <- downloadHandler(
    filename = "job_market_clean.csv",
    content  = function(f) readr::write_csv(df_clean, f)
  )

}  # end server

shinyApp(ui, server)
