# CareerLens — Job Market Analysis Dashboard

**ITA04: Statistics with R Programming — College Capstone Project**

---

## Project Title

**Job Market Analysis — Skills Demand, Salary Insights & Skill Gap Analyzer**

## Project Objective

To analyse a realistic synthetic job-market dataset using R and R Shiny, demonstrate core statistical techniques covered in ITA04, and provide an interactive dashboard that enables job-seekers to understand market trends and identify skill gaps for their desired role.

---

## Features

| Module | What It Does |
|---|---|
| **Overview** | KPI summary cards + filtered charts for job postings, salary, experience, employment type |
| **Skills Demand** | Top 10 / Top 20 in-demand skills, role-wise and location-wise skill analysis, skill categories |
| **Salary & Location** | Full descriptive statistics (mean, median, mode, SD, variance, quartiles, percentiles) + salary charts |
| **Statistics & Correlation** | Pearson correlation matrix, scatter plots, interpreted results |
| **Regression & Prediction** | Simple LR, Multiple LR, Logistic Regression, candidate salary & probability prediction |
| **Skill Gap Analyzer** | Compare candidate skills vs market demand, identify missing skills, get learning recommendations |
| **Data Quality** | Data quality report: raw counts, duplicates, missing values, clean preview, download |

---

## Technology Used

- **Primary Language**: R (v4.6.1)
- **UI Framework**: R Shiny + bslib (Bootstrap 5)
- **Visualization**: ggplot2, plotly, corrplot
- **Data Manipulation**: dplyr, tidyr
- **File I/O**: readr
- **Tables**: DT
- **Statistics**: Base R (`lm`, `glm`, `cor`, `mean`, `median`, `sd`, `var`, `quantile`, `summary`)

---

## Dataset Description

| Property | Value |
|---|---|
| Records | ~6,030 (raw) → ~5,990 (after cleaning) |
| Columns | 20 |
| Format | CSV (`data/job_market.csv`) |
| Generation | Synthetically generated using R (`data/generate_data.R`) |
| Coverage | Indian job market (majority) + select international locations |

### Dataset Generation Methodology

The dataset is synthetically generated using **R** (`data/generate_data.R`) with the following methodology:

1. **Job titles** are sampled from 25 realistic titles with realistic frequency weights (not uniform).
2. **Locations** are sampled with Indian cities forming the majority (Bengaluru, Hyderabad, Chennai, etc. are most common).
3. **Salary** is computed using a statistically-motivated formula:
   `salary = base_salary × experience_multiplier × location_premium × company_size_premium × industry_premium + noise`
   where noise is drawn from a normal distribution (±12%), making the data realistic rather than perfectly linear.
4. **Skills** are drawn from a role-appropriate pool for each job title, with realistic size variation (4–10 skills per job).
5. **Imperfections** are deliberately introduced: ~3% missing salary values, ~2% missing education, ~1.5% missing location, ~0.5% duplicate rows, inconsistent capitalization, and extra whitespace.

The dataset is not scraped from any real source. It is a teaching dataset designed to be statistically plausible for ITA04 coursework.

---

## Project Structure

```
CareerLens/
├── app.R                    ← Main Shiny application (UI + Server)
├── requirements.R           ← Package installer
├── README.md                ← This file
├── DOCUMENTATION.md         ← Academic documentation
├── .gitignore
│
├── data/
│   ├── generate_data.R      ← R script that generates job_market.csv
│   ├── job_market.csv       ← Raw synthetic dataset (~6,030 rows)
│   └── job_market_clean.csv ← Produced automatically on first app run
│
├── R/
│   ├── helper_functions.R   ← Shared utilities (format_inr, experience_bin, etc.)
│   ├── data_cleaning.R      ← Full preprocessing pipeline
│   ├── skill_analysis.R     ← Skill demand calculation functions
│   ├── salary_analysis.R    ← Descriptive statistics functions
│   └── regression_analysis.R← lm, glm, prediction functions
│
└── www/
    └── styles.css           ← Academic UI styling
```

---

## Installation

### Prerequisites

- R 4.0 or later — [https://cran.r-project.org](https://cran.r-project.org)
- RStudio — [https://posit.co/download/rstudio-desktop](https://posit.co/download/rstudio-desktop)

### Steps (Windows + RStudio)

**Step 1** — Clone or download the project:
```
git clone https://github.com/Samxxr007/CareerLens.git
```
Or download and extract the ZIP.

**Step 2** — Open RStudio, set working directory to the project folder:
```r
setwd("D:/path/to/CareerLens")
```

**Step 3** — Install required packages (first time only):
```r
source("requirements.R")
```

**Step 4** — Launch the app:
```r
shiny::runApp()
```
Or open `app.R` in RStudio and click **Run App**.

The app will:
1. Read `data/job_market.csv`
2. Clean it and produce `data/job_market_clean.csv`
3. Open the dashboard in your browser

> **Note**: Package installation (Step 3) requires an internet connection. The app itself runs fully offline after packages are installed.

---

## How to Run

```r
# From RStudio Console (with working directory set to project root):
source("requirements.R")   # first time only
shiny::runApp()
```

---

## Course Outcomes Mapped (ITA04)

| Course Concept | Where Demonstrated |
|---|---|
| Variables, Vectors, Factors | `generate_data.R`, `helper_functions.R` |
| Data Frames | All modules — primary data structure throughout |
| Functions | `clean_text()`, `format_inr()`, `calculate_skill_demand()`, etc. |
| Control Structures | `apply_filters()`, `get_skill_category()`, imputation logic |
| File Operations | `readr::read_csv()`, `write_csv()` in `data_cleaning.R` |
| Data Cleaning | `load_and_clean()` — dedup, NA imputation, normalization |
| Data Reshaping | `tidyr::separate_rows()` in `skill_analysis.R` |
| Descriptive Statistics | `calculate_salary_summary()` — all measures |
| EDA | Overview tab — distributions, counts, filters |
| Correlation | Pearson matrix in Statistics & Correlation tab |
| Visualization | ggplot2 + plotly throughout |
| Simple Regression | `run_simple_regression()` → `lm()` |
| Multiple Regression | `run_multiple_regression()` → `lm()` with multiple predictors |
| Logistic Regression | `run_logistic_regression()` → `glm(family=binomial)` |

---

## Packages Required

```r
shiny, bslib, dplyr, tidyr, ggplot2, plotly, readr, stringr, DT, scales, corrplot
```

---

## Future Enhancements

- Integrate real-time job postings via LinkedIn / Indeed API (with appropriate permissions)
- Add time-series trend analysis (salary over months)
- Cluster analysis of job roles by skill similarity
- Resume parsing to auto-populate Skill Gap Analyzer
- Export PDF report of analysis results

---

## Screenshots

*(Add screenshots after running the demo)*

---

## License

This project is submitted as a college capstone for ITA04 — Statistics with R Programming. All datasets are synthetically generated and do not represent real individuals or organizations.
