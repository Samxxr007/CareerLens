# CareerLens 2.0 — Career Intelligence, Market Analytics & Skill Decision Engine

**ITA04: Statistics with R Programming — College Capstone Project**

---

## Project Overview

**CareerLens 2.0** transforms a statistical dashboard into a full-stack, real-time career intelligence platform. It provides interactive profile matching, dual career-fit metrics, what-if scenario simulation, cross-role transferable skill discovery, local boundary-aware job description parsing, and statistically validated salary predictions powered by an R statistical service.

### Architecture

CareerLens 2.0 uses a modern 3-layer decoupled architecture:

```
┌─────────────────────────────────────────────────────────────┐
│              Layer A: React + TypeScript UI                 │
│  Vite • Tailwind CSS • Lucide • Apache ECharts • Zustand    │
│  Port: 5173 (Proxies /api to Node.js backend)               │
└──────────────────────────────┬──────────────────────────────┘
                               │ HTTP / JSON
┌──────────────────────────────▼──────────────────────────────┐
│           Layer B: Node.js + Express Orchestration          │
│  TypeScript • In-Memory Caching • API Normalization         │
│  Port: 3001                                                 │
└──────────────────────────────┬──────────────────────────────┘
                               │ HTTP / JSON
┌──────────────────────────────▼──────────────────────────────┐
│             Layer C: R 4.6.1 + Plumber API                  │
│  Pure R Analytical Engine • 6,000 Clean Dataset Records     │
│  Port: 8001                                                 │
└─────────────────────────────────────────────────────────────┘
```

> **Fallback Mode:** The original standalone Shiny application (`app.R`) is fully preserved and can be run independently via `shiny::runApp()`.

---

## Quick Start (Single Command)

### Prerequisites
1. **Node.js** (v18+) & **npm** installed.
2. **R** (v4.0+) with `plumber`, `dplyr`, `tidyr`, `readr`, `stringr`, `jsonlite` installed.

### Launching CareerLens 2.0
In the repository root directory, run:

```bash
# 1. Install root dependencies (once)
npm install

# 2. Start all three layers simultaneously
npm run dev
```

This single command boots:
- **Layer C (R Plumber)** at `http://localhost:8001`
- **Layer B (Node.js API)** at `http://localhost:3001`
- **Layer A (React Frontend)** at `http://localhost:5173`

Open **http://localhost:5173** in any browser to use CareerLens 2.0.

### Running Individual Services

```bash
# R Plumber API only (Port 8001)
npm run start:r

# Node.js Backend only (Port 3001)
npm run start:server

# React Frontend only (Port 5173)
npm run start:client

# Run automated R analytical test suite (76/76 tests)
npm run test:r
```

### Running the Legacy Shiny Fallback

If you prefer running the original pure R Shiny application:

```r
shiny::runApp()
```

---

## 8 Application Modules in CareerLens 2.0

| Module | Route | Capabilities |
|---|---|---|
| **1. Overview Dashboard** | `/` | High-level market metrics, top in-demand skills radar, top matched roles for your active profile, and real-time backend health monitor. |
| **2. Profile Studio** | `/profile` | Centralized candidate profile editor persisted in `localStorage`. Enter skills (with canonical alias matching), experience years, education, location, and target role. |
| **3. Career Explorer** | `/career-explorer` | **Role Match Shortlist** (ranked by $\ge 80\%$ posting overlap and weighted coverage), **Deep Role Diagnostics** with Dual Fit Metrics, and **Side-by-Side Career Path Comparison** (Role A vs Role B) finding shared transferable skills. |
| **4. Skill Intelligence & What-If** | `/skill-intelligence` | **What-If Lab** with real-time before/after delta tracking (+% coverage, +% overlap, newly satisfied postings count) and **Priority Recommendation Engine** ranking missing requirements by $\text{Priority Index} = 0.70 D_{\text{role}} + 0.30 D_{\text{market}}$. |
| **5. Job Description Analyzer** | `/job-analyzer` | Paste any raw job description to perform local dictionary-based skill extraction with boundary-aware regex matching (handling `C++`, `Node.js`, `CI/CD`, standalone `R`), gap analysis, and priority benchmarking. |
| **6. Salary & Prediction Lab** | `/salary-lab` | Statistical salary prediction using Simple Linear Regression & Multiple Linear Regression ($R^2$, MAE, RMSE, F-statistic), Logistic Regression for above-median compensation, 95% prediction intervals, and extrapolation warnings. |
| **7. Market Intelligence** | `/market-intelligence` | Interactive market salary distributions, experience histograms, role-based salary boxplots, and Pearson correlation matrix with statistical interpretations. |
| **8. Data Quality & Audit** | `/data-quality` | Transparent data quality audit (6,030 raw $\to$ 6,000 clean records, 30 duplicate postings removed, 180 preserved missing salaries), schema checks, and CSV download links. |

---

## Mathematical Formulations & Statistical Engine

All analytical computations are performed by the pure R statistical engine:

1. **Distinct Skill Coverage**:
   $$\text{Coverage}_{\text{distinct}} = \frac{|\text{Candidate Skills} \cap \text{Role Recognized Skills}|}{|\text{Role Recognized Skills}|} \times 100$$

2. **Demand-Weighted Skill Coverage**:
   $$\text{Coverage}_{\text{weighted}} = \frac{\sum_{s \in \text{Matched}} D_s}{\sum_{s \in \text{All Role Skills}} D_s} \times 100$$
   where $D_s$ represents the percentage of role postings requiring skill $s$.

3. **Posting-Level Skill Overlap**:
   $$\text{Overlap}_i = \frac{|\text{Candidate Skills} \cap \text{Posting}_i \text{ Skills}|}{|\text{Posting}_i \text{ Skills}|} \times 100$$
   Reported as percentage of postings where $\text{Overlap}_i \ge 80\%$.

4. **Recommendation Priority Index**:
   $$\text{Priority Index} = 0.70 \times D_{\text{role}} + 0.30 \times D_{\text{market}}$$
   - `HIGH PRIORITY`: $\text{Priority Index} \ge 35.0\%$
   - `MEDIUM PRIORITY`: $15.0\% \le \text{Priority Index} < 35.0\%$
   - `ADDITIONAL SKILL`: $\text{Priority Index} < 15.0\%$

5. **Out-of-Sample Regression Metrics**:
   $$\text{MAE} = \frac{1}{n} \sum |y_i - \hat{y}_i|, \quad \text{RMSE} = \sqrt{\frac{1}{n} \sum (y_i - \hat{y}_i)^2}, \quad R^2_{\text{test}} = 1 - \frac{\sum (y_i - \hat{y}_i)^2}{\sum (y_i - \bar{y}_{\text{test}})^2}$$

---

## Dataset Transparency

- **Source**: 6,030 synthetic records generated with reproducible seed (`set.seed(42)`).
- **Clean Records**: 6,000 clean postings preprocessed via `R/data_cleaning.R` after deduplicating 30 duplicate records.
- **52 Fictional Companies**: Clearly fictional employer names (*Apex Analytics Labs*, *NexaTech Solutions*, *QuantumLogic Systems*) to prevent confusion with real corporate entities.
- **Missing Data Handling**: 180 records with unstated compensation are preserved as `NA` (never silently imputed) to maintain statistical modeling integrity.

---

## Verification & Testing

CareerLens comes with an automated analytical test suite covering 76 test assertions:

```bash
npm run test:r
```

Output:
```
===================================================================
   CareerLens: Automated Analytical Test Suite (Pure R)
===================================================================
--- 1. Testing Dataset & Cleaning Pipeline --- [PASS x 8]
--- 2. Testing Skill Analysis & Deduplication --- [PASS x 4]
--- 3. Testing Career Fit Engine & Dual Metrics --- [PASS x 18]
--- 4. Testing Recommendation Engine --- [PASS x 6]
--- 5. Testing Model Validation Utilities --- [PASS x 9]
--- 6. Testing Regression Models & Predictions --- [PASS x 13]
--- 7. Testing Job Description Analyzer --- [PASS x 7]
--- 8. Testing Edge Cases & Robustness --- [PASS x 4]
===================================================================
   TEST RESULTS: 76 / 76 PASSED (100% SUCCESS)
===================================================================
```

---

## Repository Structure

```
Career Lens/
├── package.json                   # Root orchestrator (npm run dev)
├── app.R                          # Standalone R Shiny fallback app
├── api/
│   └── plumber.R                  # 14-endpoint R Plumber REST API service
├── scripts/
│   └── start-plumber.R            # Launcher for R Plumber on port 8001
├── server/                        # Layer B: Node.js + Express Backend
│   ├── src/
│   │   ├── config/env.ts          # Server environment settings
│   │   ├── services/rPlumber.service.ts # Axios client with in-memory caching
│   │   ├── routes/api.routes.ts   # Express route handlers
│   │   ├── app.ts                 # Express application configuration
│   │   └── server.ts              # Server lifecycle entry point
│   ├── package.json
│   └── tsconfig.json
├── client/                        # Layer A: React + TypeScript Frontend
│   ├── src/
│   │   ├── components/            # Sidebar, Header, MetricCard, SkillChip, Layout
│   │   ├── pages/                 # 8 interactive dashboard pages
│   │   ├── services/api.ts        # TanStack Query API client
│   │   ├── stores/useProfileStore.ts # Zustand candidate profile store
│   │   ├── types/index.ts         # TypeScript data contracts
│   │   ├── App.tsx                # React Router setup
│   │   └── main.tsx
│   ├── package.json
│   └── vite.config.ts
├── data/
│   ├── generate_data.R            # Dataset generator in pure R
│   ├── job_market.csv             # Raw generated dataset (6,030 rows)
│   └── job_market_clean.csv       # Preprocessed clean dataset (6,000 rows)
├── R/                             # Pure R statistical analytical library
│   ├── helper_functions.R
│   ├── data_cleaning.R
│   ├── skill_analysis.R
│   ├── salary_analysis.R
│   ├── career_fit.R
│   ├── recommendation_engine.R
│   ├── job_description_analysis.R
│   ├── regression_analysis.R
│   └── model_validation.R
└── tests/
    └── test_functions.R           # 76-assertion automated test suite
```
