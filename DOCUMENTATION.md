# DOCUMENTATION.md
# CareerLens — Interactive Career Decision-Support Application
# ITA04: Statistics with R Programming — Academic Capstone Documentation

---

## 1. Aim & Problem Statement

### Aim
To design, implement, and validate an interactive career decision-support application using R and R Shiny that processes job-market data to enable students and job-seekers to evaluate their career fit, simulate skill acquisition scenarios, compare career trajectories, parse job descriptions, and predict compensation using statistically defensible regression models.

### Problem Statement
Static dashboards and labor-market summaries provide high-level averages but fail to answer individual questions such as:
> *"Given my current skills and experience, which career paths fit my profile, what specific requirements am I missing, and how will acquiring a new skill impact my opportunities?"*

CareerLens transforms static data into an interactive decision-support system answering three fundamental questions:
1. **What should I improve?** (Identified through role-specific skill gap analysis)
2. **Why is this important according to the dataset?** (Evidence-backed through the Priority Index: $0.70 D_{\text{role}} + 0.30 D_{\text{market}}$, posting counts, and empirical co-occurrence)
3. **What measurable difference does the proposed change make?** (Quantified in real time via the What-If Simulator with before/after coverage and overlap deltas)

---

## 2. Methodology & Mathematical Formulations

### 2.1 Dataset Generation & Data Cleaning Pipeline
- **Script**: `data/generate_data.R` using deterministic pseudo-random seeds (`set.seed(42)`).
- **Volume**: 6,030 raw records generated $\to$ 30 duplicates removed $\to$ 6,000 clean records.
- **Fictional Enterprise Pool**: 52 varied fictional companies (e.g., *Apex Analytics Labs, NexaTech Solutions, DataSphere Informatics, QuantumLogic Systems*) to prevent implying real hiring activities.
- **Currency Standardization**: All compensation figures are standardized as synthetic annual INR-equivalent benchmarks across domestic and international locations.
- **Preserved Missing Salaries**: 180 records with missing `salary_inr` are strictly preserved as `NA` (never silently imputed with group medians) to maintain statistical purity in regression modeling. These rows remain available for skill demand, location, and role frequency analyses that do not require salary.

---

### 2.2 Candidate Profile & Career Fit Engine

CareerLens evaluates candidate alignment using three transparent, statistically defensible measures:

#### A. Distinct Skill Coverage (%)
Measures the proportion of distinct, recognized skills demanded for the target role that the candidate possesses:
$$\text{Skill Coverage}_{\text{distinct}} = \frac{|\text{Candidate Skills} \cap \text{Role Distinct Skills}|}{|\text{Role Distinct Skills}|} \times 100\%$$

#### B. Demand-Weighted Skill Coverage (%)
Weights each recognized skill by its observed posting demand percentage ($D_s$) in the target role:
$$\text{Skill Coverage}_{\text{weighted}} = \frac{\sum_{s \in \text{Matched}} D_s}{\sum_{s \in \text{All Role Skills}} D_s} \times 100\%$$

#### C. Posting-Level Skill Overlap (≥ 80% Threshold)
Calculates what percentage of individual job postings in that role have at least 80% of their requirements satisfied:
$$\text{Overlap}_i = \frac{|\text{Candidate Skills} \cap \text{Posting}_i \text{ Skills}|}{|\text{Posting}_i \text{ Skills}|} \times 100\%$$
$$\text{Posting-Level Match} = \frac{1}{N} \sum_{i=1}^N \mathbb{I}(\text{Overlap}_i \ge 80.0\%) \times 100\%$$

*Note: Neither metric is represented as a probability of employment; they measure skill-requirement overlap.*

---

### 2.3 Priority Recommendation Engine

To prioritize missing competencies without hardcoding or unverified claims, CareerLens uses an explainable ranking heuristic:

$$\text{Priority Index} = 0.70 \times D_{\text{role}} + 0.30 \times D_{\text{market}}$$

Where:
- $D_{\text{role}} = \frac{N_{\text{role\_skill}}}{N_{\text{role}}} \times 100\%$ (Target role demand percentage)
- $D_{\text{market}} = \frac{N_{\text{market\_skill}}}{N_{\text{total}}} \times 100\%$ (Global market demand percentage)

#### Categorization Tiers
- **HIGH PRIORITY**: $\text{Priority Index} \ge 35.0\%$ (frequently observed core requirements)
- **MEDIUM PRIORITY**: $15.0\% \le \text{Priority Index} < 35.0\%$ (moderate-demand profile enhancers)
- **ADDITIONAL SKILL**: $\text{Priority Index} < 15.0\%$ (niche or specialized tools)

#### Empirical Co-occurrence Analysis
For each recommended skill, the engine queries the subset of role postings requiring that skill and calculates the empirical percentage containing the candidate's existing skills (e.g., $77\%$ of MySQL postings also list Excel, $74\%$ list SQL). Co-occurrence reflects observed posting pairing, not a mandatory prerequisite.

---

### 2.4 What-If Simulator & Career Path Comparison

#### What-If Deltas
$$\Delta \text{Coverage} = \text{Skill Coverage}_{\text{Proposed}} - \text{Skill Coverage}_{\text{Baseline}}$$
$$\Delta \text{Overlap} = \text{Posting Match}_{\text{Proposed}} - \text{Posting Match}_{\text{Baseline}}$$
$$\text{Newly Satisfied Postings} = \sum_{i=1}^N \mathbb{I}(\text{Overlap}_{i, \text{base}} < 80\% \land \text{Overlap}_{i, \text{prop}} \ge 80\%)$$

#### Career Path Comparison
Evaluates shared transferable competencies between Role A and Role B:
$$\text{Transferable Skills} = \text{Skills}_A \cap \text{Skills}_B$$
$$\text{Unique to Role A} = \text{Skills}_A \setminus \text{Skills}_B, \quad \text{Unique to Role B} = \text{Skills}_B \setminus \text{Skills}_A$$

---

### 2.5 Offline Boundary-Aware Job Description Parsing

Implemented in `R/job_description_analysis.R` using boundary-aware regex matching against a dictionary compiled from the clean dataset:
- Boundary pattern: `(?i)(?<=[^a-zA-Z0-9+#]|^)<skill>(?=[^a-zA-Z0-9+#]|$)`
- Handles special symbols: `C++`, `C#`, `.NET`, `Node.js`, `CI/CD`, `REST API`, `scikit-learn`, `Power BI`.
- Standalone single-letter "R" regex: `(?<=[\\s,;./()\\[\\]{}:<>]|^)R(?=[\\s,;./()\\[\\]{}:<>]|$)` to prevent false positive substring collisions inside words like "Research" or "Requirements".

---

### 2.6 Statistical Modeling & Leak-Free Evaluation

All models use a deterministic 80% Training / 20% Testing holdout partition (`set.seed(42)`) excluding missing salaries:

#### A. Simple Linear Regression
$$\text{salary\_inr} = \beta_0 + \beta_1 \cdot \text{experience\_years} + \epsilon$$

#### B. Multiple Linear Regression
$$\text{salary\_inr} = \beta_0 + \beta_1 \cdot \text{exp} + \beta_2 \cdot \text{skills} + \boldsymbol{\beta}_{\text{edu}} + \beta_4 \cdot \text{size} + \boldsymbol{\beta}_{\text{tier}} + \epsilon$$
Evaluated with residual diagnostics (Standardized residuals vs Fitted values).

#### C. Logistic Regression (High Salary Classifier)
Binary outcome: $Y = 1$ if $\text{salary\_inr} \ge \text{Median}_{\text{train}}(\text{salary\_inr})$, else $0$.
Threshold is computed strictly on the training partition to prevent data leakage.
Evaluated on the 20% test partition:
$$\text{Accuracy} = \frac{TP + TN}{\text{Total}}, \quad \text{Precision} = \frac{TP}{TP + FP}, \quad \text{Recall} = \frac{TP}{TP + FN}, \quad F_1 = \frac{2 \cdot P \cdot R}{P + R}$$

#### D. Prediction Interval & Extrapolation Safety
Point estimate with 95% individual prediction interval:
$$\hat{y} \pm t_{n-p, 0.975} \cdot s \sqrt{1 + \mathbf{x}_0^T (\mathbf{X}^T \mathbf{X})^{-1} \mathbf{x}_0}$$
Extrapolation safety checks warn when user inputs exceed the maximum observed training experience (18 years).

---

## 3. Test & Verification Results

Executed via `tests/test_functions.R` and `validate.R`:
- **Total Tests**: **76 / 76 Passed (100% Success)**.
- **Dataset Checks**: 6,030 raw rows, 6,000 clean rows, 52 unique fictional companies, 180 preserved missing salaries.
- **Career Fit & What-If**: Hand-crafted mathematical proofs verified (Distinct Coverage: 42.9%, Overlap $\ge 80\%$: 33.3%, Overlap $\ge 50\%$: 66.7%).
- **Observed Holdout Model Performance**:
  - SLR Train $R^2 = 0.2312$ | Test $R^2 = 0.2443$ | Test RMSE = ₹3,99,200
  - MLR Train $R^2 = 0.4468$ | Test $R^2 = 0.4570$ | Test RMSE = ₹3,99,140
  - Logistic Test Accuracy = 73.1% | Test Precision = 73.4% | Test F1 Score = 72.7%
- **Shiny Application**: Successfully parsed and initialized as `shiny.appobj`.

---

## 4. Key Questions & Defenses for Capstone Viva

| Viva Question | Concise Academic Answer |
|---|---|
| **Why did you use synthetic data instead of scraping?** | To maintain complete statistical control over realistic distributions, introduce documented real-world imperfections for preprocessing demonstrations, and ensure reproducibility without legal or rate-limit constraints. |
| **Why did you preserve missing salaries instead of imputing them?** | Imputing missing outcomes with group or global medians distorts the conditional distribution of the response variable, artificially depresses residual variance, and biases standard error estimates in regression models. Excluding missing outcomes from regression training preserves unbiased estimators. |
| **Why report two fit metrics instead of one?** | Distinct Skill Coverage evaluates breadth across the entire role syllabus, whereas Posting-Level Match (≥80%) evaluates how often a candidate qualifies for actual individual job vacancies. Neither represents hiring probability. |
| **How does the Priority Index avoid data fabrication?** | Every component ($D_{\text{role}}$ and $D_{\text{market}}$) is computed directly from counts of postings in the dataset. The linear weighting ($0.70/0.30$) is an explicit, transparent ranking heuristic, not an arbitrary black-box score. |
| **Why evaluate models on held-out test data?** | Reporting training accuracy inflates perceived model performance due to potential overfitting. Evaluating on a 20% holdout provides honest, generalized out-of-sample performance metrics ($R^2$, RMSE, precision, F1 score). |
| **How did you prevent data leakage in logistic regression?** | The high-salary classification threshold was computed exclusively from the 80% training partition's median salary, rather than the entire dataset. This ensures the test set evaluates predictions against an independently established threshold. |
| **What does Pearson correlation measure here?** | Pearson $r$ measures linear association between numeric variables (e.g., experience vs salary: $r \approx 0.48$). It reflects moderate positive association while acknowledging that real salaries have significant non-linear variance. |

---

## 5. System Architecture: CareerLens 2.0 (Decoupled 3-Layer System)

In addition to the standalone R Shiny interactive application (`app.R`), CareerLens 2.0 implements an enterprise 3-tier decoupled architecture designed for high reactivity and real-time decision-support:

```
┌─────────────────────────────────────────────────────────────┐
│              Layer A: React + TypeScript UI                 │
│  Vite • Tailwind CSS • Apache ECharts • Zustand • TanStack  │
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

1. **Layer C (R Plumber Analytical Service - Port 8001)**:
   - Houses the statistical engine, data structures, and mathematical models in pure R.
   - 14 REST endpoints (`/health`, `/metadata`, `/market/*`, `/analyze/*`, `/simulate/*`, `/predict/*`, `/data-quality`).
   - Loads clean dataset and pre-computes statistical models once into memory on startup.

2. **Layer B (Node.js + Express Middleware - Port 3001)**:
   - High-throughput API gateway and orchestration middle tier.
   - In-memory cache for market-wide aggregates with 10-minute TTL to reduce redundant R evaluation.
   - Normalizes errors and standardizes API responses into `{ success: boolean, data: T, meta?: any }`.

3. **Layer A (React + TypeScript Frontend - Port 5173)**:
   - Modern, reactive, desktop-optimized dashboard with 8 dedicated modules.
   - Client-side profile state persisted across sessions with Zustand.
   - Interactive data visualizations with Apache ECharts (Salary distribution, radar charts, skill co-occurrence).
   - Instant response without full-page reloads.

4. **Standalone Shiny Fallback (`app.R`)**:
   - Preserved 100% operational as a single-file R Shiny application for environments where Node.js is not running.

