# DOCUMENTATION.md
# CareerLens — Job Market Analysis Dashboard
# ITA04: Statistics with R Programming — Academic Documentation

---

## Aim

To build an interactive job market analysis application using R and R Shiny that demonstrates data cleaning, exploratory data analysis (EDA), descriptive statistics, correlation analysis, regression modelling, and skill gap analysis on a synthetically-generated job market dataset.

---

## Problem Statement

The IT job market is competitive and rapidly evolving. Job seekers often lack clear visibility into which skills are in highest demand, what salaries to expect for a given role and experience level, and where their skill gaps lie relative to their desired role. This project addresses these challenges by building an end-to-end analytics pipeline in R that processes job-posting data and delivers actionable insights through an interactive Shiny dashboard.

---

## Objectives

1. Generate a realistic synthetic job market dataset using R.
2. Implement a data preprocessing pipeline that detects and corrects data quality issues.
3. Perform Exploratory Data Analysis on job postings, skills, and salaries.
4. Compute descriptive statistics (mean, median, mode, SD, variance, quartiles, percentiles).
5. Calculate Pearson correlation between numerical variables.
6. Build and evaluate a Simple Linear Regression model to predict salary from experience.
7. Build a Multiple Linear Regression model using multiple predictors.
8. Build a Logistic Regression model to classify high vs low salary outcomes.
9. Implement a Skill Gap Analyzer that compares a candidate's skills against market demand.
10. Present all results through an interactive academic-style Shiny dashboard.

---

## Dataset Description

| Property | Detail |
|---|---|
| File | `data/job_market.csv` |
| Generation Script | `data/generate_data.R` |
| Records | ~6,030 (raw) |
| Columns | 20 |
| Primary Language | R |

### Key Columns

| Column | Type | Description |
|---|---|---|
| `job_id` | Character | Unique posting identifier |
| `job_title` | Character | Job role title |
| `company` | Character | Company name |
| `location` | Character | City |
| `state` | Character | State / Province |
| `country` | Character | Country (India dominant) |
| `industry` | Character | Industry sector |
| `employment_type` | Character | Full-Time / Part-Time / Contract / Internship |
| `experience_years` | Integer | Required years of experience |
| `education` | Character | Required education level |
| `salary_min` | Numeric | Minimum salary (INR) |
| `salary_max` | Numeric | Maximum salary (INR) |
| `salary_currency` | Character | INR or USD |
| `salary_inr` | Numeric | Annual salary in INR |
| `skills` | Character | Required skills (semicolon-separated) |
| `skill_count` | Integer | Number of skills required |
| `posted_date` | Date | Job posting date |
| `remote_type` | Character | On-Site / Hybrid / Remote |
| `company_size` | Character | Small / Medium / Large / Enterprise |
| `job_description` | Character | Short job description |

---

## Methodology

### Data Generation

The dataset is generated using `set.seed(42)` for reproducibility. The generation process:
1. Defines look-up tables for job titles, locations, companies, industries, skills, etc.
2. Samples values using `sample()` with realistic probability weights.
3. Computes salary using a multiplicative model with Gaussian noise.
4. Deliberately introduces missing values (~3%), duplicates (~0.5%), and text inconsistencies.

---

## Data Cleaning

Implemented in `R/data_cleaning.R` via the `load_and_clean()` function.

### Steps

1. **Read CSV** using `readr::read_csv()`.
2. **Check dimensions** — verify required columns exist.
3. **Detect duplicates** on business-key columns (title + company + location + experience + skills).
4. **Remove duplicates** using `duplicated()`.
5. **Text normalization** via `clean_text()`:
   - `trimws()` — remove leading/trailing whitespace
   - `gsub("\\s+", " ", x)` — collapse internal spaces
   - `tools::toTitleCase(tolower(x))` — normalize case
6. **Missing value imputation**:
   - `salary_inr`: group-wise median imputation per job title
   - `education`, `company_size`, `location`: statistical mode imputation
   - `skills`: empty string (treated as 0 skills)
7. **Type conversion**: `as.integer()`, `as.numeric()`, `as.Date()`, `as.factor()`
8. **Derived columns**: `experience_bin`, `company_size_num`, `location_tier`, `high_salary`, `salary_outlier`
9. **Outlier flagging** using IQR method (3 × IQR beyond Q1/Q3) — flagged but not removed to preserve data.
10. **Save clean CSV** to `data/job_market_clean.csv`.

---

## Exploratory Data Analysis (EDA)

Performed in the **Overview** and **Salary & Location** tabs.

- Job postings by role (bar chart)
- Job postings by location (bar chart)
- Experience distribution (histogram)
- Employment type distribution (pie chart)
- Salary distribution (histogram)
- Interactive filters: location, role, experience level, industry, employment type, remote type

---

## Skills Demand Analysis

Implemented in `R/skill_analysis.R`.

**Method:**
- `tidyr::separate_rows()` explodes the semicolon-delimited skills column into a long-format data frame.
- Skill frequency is computed with `dplyr::count()`.
- Demand percentage = (skill job count / total jobs) × 100.
- Skills are categorised into: Programming Languages, Web & Frameworks, Cloud & DevOps, Database & Data, Analytics & ML, Tools & Practices, Soft Skills, Security, Infrastructure.

**Outputs:**
- Top 10 / Top 20 skill ranking table (Rank | Skill | Count | Demand %)
- Role-specific skill demand (filtered by job title)
- Location-specific skill demand (filtered by location)

---

## Salary Statistical Analysis

Implemented in `R/salary_analysis.R` via `calculate_salary_summary()`.

### Measures Computed

| Measure | R Function |
|---|---|
| Count | `length()` |
| Mean | `mean()` |
| Median | `median()` |
| Mode | Custom `stat_mode()` |
| Minimum / Maximum | `min()`, `max()` |
| Range | `max() - min()` |
| Variance | `var()` |
| Standard Deviation | `sd()` |
| Q1, Q3 | `quantile(0.25)`, `quantile(0.75)` |
| IQR | `IQR()` |
| 10th / 90th Percentile | `quantile(0.10)`, `quantile(0.90)` |
| Coefficient of Variation | `sd / mean × 100` |

---

## Correlation Analysis

Implemented in the **Statistics & Correlation** tab.

**Variables analysed:**
- `experience_years`
- `salary_inr`
- `skill_count`
- `company_size_num` (ordinal encoding of company size)

**Method:**
- Pearson correlation: `cor(x, method="pearson")`
- Visualised as a colour-coded heatmap using `corrplot::corrplot()`
- Interpretations are generated dynamically based on computed r values using `stat_label()` (strong/moderate/weak, positive/negative)

---

## Simple Linear Regression

**Model:** `lm(salary_inr ~ experience_years, data=df_model)`

**Outputs:**
- Intercept and slope coefficients
- R² (coefficient of determination)
- p-value for slope coefficient
- Regression equation as a readable string
- Scatter plot with regression line (plotly)
- Coefficient table with standard errors and t-values

**Interpretation:** The slope represents the expected change in annual salary (INR) per additional year of experience.

---

## Multiple Linear Regression

**Model:**
```
lm(salary_inr ~ experience_years + skill_count + education +
                company_size_num + location_tier, data=df_model)
```

**Categorical encoding:**
- `education` and `location_tier` are converted to factors; R creates dummy variables automatically.
- `company_size_num` is ordinal (Small=1, Medium=2, Large=3, Enterprise=4).

**Outputs:**
- R², Adjusted R², F-statistic, overall p-value
- Full coefficient table
- Actual vs Predicted salary scatter plot

---

## Logistic Regression

**Objective:** Classify whether a job offers a high salary (above median) or low/mid salary.

**Threshold:** Median of `salary_inr` in the clean dataset.
- `high_salary = 1` if `salary_inr >= median`
- `high_salary = 0` otherwise

**Model:**
```
glm(high_salary ~ experience_years + skill_count + education + company_size_num,
    family = binomial(link="logit"), data=df_model)
```

**Outputs:**
- Logit coefficients (log-odds)
- Model accuracy, sensitivity, specificity (from confusion matrix)
- Probability prediction for user-entered candidate profile
- Predicted class: "High Salary" or "Low / Mid Salary"

---

## Skill Gap Methodology

Implemented in `R/skill_analysis.R` (role_skill_demand) and the **Skill Gap Analyzer** tab.

**Steps:**
1. User selects their current skills and desired job role.
2. System calls `role_skill_demand(df_clean, target_role)` to get actual market skill demand for that role.
3. Each required skill is classified as **Matched** (candidate has it) or **Missing** (candidate lacks it).
4. Missing skills are ranked by market demand percentage (derived from the dataset — not hard-coded).
5. Top 5 missing skills by demand are presented as **Recommended Skills to Learn**.
6. Gap Score = (missing skills / total required skills) × 100%.

---

## Results

Key findings from the generated dataset (actual values shown in app):

- Bengaluru, Hyderabad, and Chennai account for the largest share of job postings.
- SQL, Python, and Git consistently rank among the top 5 most in-demand skills.
- Data Scientist and Machine Learning Engineer roles command the highest median salaries.
- Pearson correlation between experience and salary is moderate positive (typically r ≈ 0.40–0.55), reflecting real-world noise.
- Simple linear regression shows significant positive slope for experience → salary (p < 0.001).
- Multiple regression with all predictors achieves noticeably higher R² than the simple model.
- Logistic regression achieves ~68–72% accuracy in classifying high/low salary jobs.

*(Exact values are computed live from the dataset when the app runs.)*

---

## Conclusion

CareerLens successfully demonstrates the full ITA04 statistical analysis pipeline on a realistic job market dataset:
- Data cleaning and preprocessing in R
- Descriptive statistics and EDA
- Correlation analysis
- Simple, Multiple, and Logistic Regression
- Interactive Shiny-based presentation

The Skill Gap Analyzer provides a practical, data-driven tool that job seekers can use to prioritize their learning based on actual market demand.

---

## Limitations

1. The dataset is synthetically generated and does not represent real job postings.
2. Salary predictions carry uncertainty (reflected in the 95% prediction interval shown in the app).
3. Skill demand is based on skill frequency in job descriptions, which may not perfectly reflect actual hiring decisions.
4. The logistic regression model uses a binary threshold (median salary); real-world classification may require more nuanced thresholds.
5. The dataset covers a snapshot period (April 2025 – October 2026) and does not reflect long-term market trends.

---

## Future Scope

1. Integrate a real job-posting dataset (Kaggle, LinkedIn, etc.) with proper licensing.
2. Add time-series analysis of skill demand and salary trends over months/years.
3. Use clustering (k-means) to group job roles by skill similarity.
4. Implement a resume parser that auto-fills the Skill Gap Analyzer from a PDF resume.
5. Add a PDF/HTML export for the analysis report.
6. Deploy the Shiny app to shinyapps.io for web access.
