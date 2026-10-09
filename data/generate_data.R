# =============================================================================
# generate_data.R
# CareerLens — ITA04: Statistics with R Programming
# -----------------------------------------------------------------------------
# Generates a synthetic but statistically realistic job market dataset.
# Run this script ONCE to create: data/job_market.csv
#
# Usage (from project root in RStudio):
#   source("data/generate_data.R")
# =============================================================================

set.seed(42)   # reproducibility

`%||%` <- function(a, b) if (!is.null(a)) a else b  # null-coalescing helper

N <- 6000      # target number of job postings

# ---------------------------------------------------------------------------
# 1. LOOKUP TABLES
# ---------------------------------------------------------------------------

job_titles <- c(
  "Software Engineer", "Software Developer", "Frontend Developer",
  "Backend Developer", "Full Stack Developer", "React Developer",
  "Java Developer", "Python Developer", "Data Analyst",
  "Data Scientist", "Machine Learning Engineer", "Data Engineer",
  "DevOps Engineer", "Cloud Engineer", "QA Engineer",
  "Automation Test Engineer", "Business Analyst", "Product Analyst",
  "UI/UX Designer", "Cybersecurity Analyst", "Database Administrator",
  "System Administrator", "Product Manager", "Technical Support Engineer",
  "Project Coordinator"
)

# Relative weights — not uniform
title_weights <- c(
  180, 160, 140, 140, 130, 100, 120, 110, 200,
  160, 120, 110, 130, 100, 130, 90, 150, 100,
  80,  70,  80,  70,  90,  100, 80
)

industries <- c(
  "Information Technology", "Banking & Finance", "E-Commerce",
  "Healthcare", "Telecommunications", "Manufacturing",
  "Consulting", "EdTech", "Logistics", "Media & Entertainment"
)
industry_weights <- c(35, 15, 12, 8, 7, 5, 8, 4, 3, 3)

employment_types <- c("Full-Time", "Part-Time", "Contract", "Internship")
emp_weights      <- c(75, 5, 12, 8)

education_levels <- c("B.Tech", "B.E.", "BCA", "MCA", "M.Tech",
                       "MBA", "B.Sc", "M.Sc", "Diploma", "Ph.D")
edu_weights      <- c(28, 18, 10, 12, 10, 8, 7, 4, 2, 1)

remote_types <- c("On-Site", "Hybrid", "Remote")
remote_weights <- c(55, 30, 15)

company_sizes <- c("Small", "Medium", "Large", "Enterprise")
size_weights  <- c(20, 30, 30, 20)

# Company name pools (realistic-sounding Indian + global tech companies)
companies_india <- c(
  "Infosys", "TCS", "Wipro", "HCL Technologies", "Tech Mahindra",
  "Cognizant", "Capgemini India", "Mphasis", "Hexaware Technologies",
  "LTIMindtree", "Persistent Systems", "Birlasoft", "Mastech Digital",
  "Zensar Technologies", "NIIT Technologies", "Coforge", "Firstsource",
  "Cyient", "Sonata Software", "Kellton Tech", "Subex", "Infoedge",
  "Freshworks", "Zoho Corporation", "Chargebee", "Razorpay", "PhonePe",
  "Paytm", "PolicyBazaar", "Swiggy", "Zomato", "Meesho", "Groww",
  "BrowserStack", "Druva", "Postman", "Unacademy", "Byju's", "Nykaa",
  "Ola", "Ather Energy", "Urban Company", "Slice", "Cred", "Zerodha",
  "Juspay", "Fractal Analytics", "MuSigma", "Latent View Analytics",
  "Sigmoid", "Tiger Analytics", "Dataweave", "CloudSEK", "Darwinbox",
  "Haptik", "Leadsquared", "Whatfix", "Hasura", "MinIO India",
  "GlobalLogic India", "Sapient India", "EPAM Systems India"
)
companies_global <- c(
  "Accenture", "IBM", "Deloitte", "PwC", "EY Technology",
  "Microsoft", "Google", "Amazon", "Meta", "Salesforce",
  "SAP", "Oracle", "Adobe", "Cisco", "Dell Technologies",
  "HP Enterprise", "Siemens", "Bosch", "ABB", "ThoughtWorks"
)
all_companies <- c(companies_india, companies_global)

# Locations with realistic Indian dominance
locations_india <- c(
  "Bengaluru", "Hyderabad", "Chennai", "Pune", "Mumbai",
  "Delhi", "Gurugram", "Noida", "Kochi", "Coimbatore",
  "Ahmedabad", "Jaipur", "Kolkata", "Indore", "Thiruvananthapuram",
  "Visakhapatnam", "Nagpur", "Chandigarh"
)
loc_india_weights <- c(
  200, 160, 150, 140, 130,
  110, 120, 110, 70,  50,
  50,  40,  60,  35,  30,
  25,  20,  20
)
locations_intl <- c("London", "Toronto", "Singapore", "Dubai", "New York", "Berlin")
loc_intl_weights <- c(15, 10, 20, 25, 10, 8)

states_india <- c(
  "Karnataka", "Telangana", "Tamil Nadu", "Maharashtra", "Maharashtra",
  "Delhi", "Haryana", "Uttar Pradesh", "Kerala", "Tamil Nadu",
  "Gujarat", "Rajasthan", "West Bengal", "Madhya Pradesh", "Kerala",
  "Andhra Pradesh", "Maharashtra", "Punjab"
)
states_intl <- c("England", "Ontario", "Singapore", "Dubai", "New York", "Berlin")

# ---------------------------------------------------------------------------
# 2. SKILL POOLS PER JOB FAMILY
# ---------------------------------------------------------------------------

skill_pools <- list(
  "Software Engineer"          = c("Java","Python","C++","SQL","Git","REST API","Linux","Docker","Agile","Spring Boot"),
  "Software Developer"         = c("JavaScript","Java","Python","SQL","Git","React","Node.js","REST API","Agile","MySQL"),
  "Frontend Developer"         = c("JavaScript","React","HTML","CSS","TypeScript","Vue","Angular","Figma","Git","Tailwind CSS"),
  "Backend Developer"          = c("Node.js","Java","Python","SQL","MySQL","PostgreSQL","REST API","Docker","Git","Redis"),
  "Full Stack Developer"       = c("React","Node.js","JavaScript","SQL","MongoDB","Docker","Git","TypeScript","Express","AWS"),
  "React Developer"            = c("React","JavaScript","TypeScript","HTML","CSS","Redux","Git","REST API","Node.js","Figma"),
  "Java Developer"             = c("Java","Spring Boot","SQL","Maven","Git","Hibernate","REST API","MySQL","Docker","JUnit"),
  "Python Developer"           = c("Python","Django","Flask","SQL","PostgreSQL","Git","REST API","Pandas","Docker","Linux"),
  "Data Analyst"               = c("SQL","Excel","Power BI","Tableau","Python","Pandas","NumPy","Statistics","Matplotlib","MySQL"),
  "Data Scientist"             = c("Python","Pandas","NumPy","scikit-learn","SQL","TensorFlow","Statistics","Jupyter","Matplotlib","R"),
  "Machine Learning Engineer"  = c("Python","TensorFlow","PyTorch","scikit-learn","SQL","Pandas","NumPy","Docker","Git","MLflow"),
  "Data Engineer"              = c("Python","SQL","Spark","Hadoop","AWS","Azure","Airflow","Kafka","PostgreSQL","dbt"),
  "DevOps Engineer"            = c("AWS","Docker","Kubernetes","Jenkins","Linux","Terraform","Git","CI/CD","Ansible","Bash"),
  "Cloud Engineer"             = c("AWS","Azure","GCP","Terraform","Docker","Kubernetes","Linux","Python","Git","Networking"),
  "QA Engineer"                = c("Selenium","Java","Python","Jira","SQL","TestNG","Git","Manual Testing","Agile","Postman"),
  "Automation Test Engineer"   = c("Selenium","Java","Cypress","Python","Jira","TestNG","Git","REST Assured","Agile","SQL"),
  "Business Analyst"           = c("SQL","Excel","Power BI","Tableau","Jira","Communication","Agile","Requirements Analysis","Visio","MS Office"),
  "Product Analyst"            = c("SQL","Python","Excel","Tableau","Google Analytics","Jira","Communication","A/B Testing","Product Management","Statistics"),
  "UI/UX Designer"             = c("Figma","Adobe XD","Sketch","UX Research","Prototyping","Wireframing","Canva","HTML","CSS","Communication"),
  "Cybersecurity Analyst"      = c("Network Security","SIEM","Python","Linux","Firewalls","Vulnerability Assessment","Ethical Hacking","SQL","Wireshark","ISO 27001"),
  "Database Administrator"     = c("SQL","MySQL","PostgreSQL","Oracle DB","MongoDB","Backup & Recovery","Linux","Performance Tuning","Shell Scripting","Python"),
  "System Administrator"       = c("Linux","Windows Server","Networking","VMware","Active Directory","Shell Scripting","Python","Backup & Recovery","Docker","Ansible"),
  "Product Manager"            = c("Agile","Jira","Communication","Roadmapping","Stakeholder Management","SQL","Excel","Product Strategy","Leadership","UX Research"),
  "Technical Support Engineer" = c("Customer Support","Linux","Windows","Networking","SQL","Troubleshooting","Communication","Jira","Python","Documentation"),
  "Project Coordinator"        = c("Project Management","MS Office","Excel","Jira","Communication","Agile","Documentation","Stakeholder Management","Leadership","MS Project")
)

# Soft skills to randomly sprinkle
soft_skills <- c("Communication","Teamwork","Problem Solving","Leadership","Time Management")

# ---------------------------------------------------------------------------
# 3. SALARY PARAMETERS
# ---------------------------------------------------------------------------

# Base annual salary in INR (lakhs) per job title — approximate market rate
base_salary_lpa <- c(
  6.5, 6.0, 5.5, 6.5, 7.0, 6.5, 6.0, 6.5, 5.0,
  9.0, 11.0, 9.5, 8.5, 9.0, 5.5, 5.5, 6.5, 7.0,
  5.5, 7.5, 6.0, 5.0, 10.0, 4.5, 4.5
)
names(base_salary_lpa) <- job_titles

# Experience premium: salary multiplier per year of experience
exp_premium <- function(yrs) {
  # Diminishing returns, with noise
  base <- 1 + (0.10 * yrs) - (0.003 * yrs^2)
  pmax(base, 0.8)
}

# Location premium factors (multiplier)
loc_premium <- c(
  Bengaluru=1.20, Hyderabad=1.10, Chennai=1.10, Pune=1.12, Mumbai=1.18,
  Delhi=1.12, Gurugram=1.20, Noida=1.10, Kochi=0.90, Coimbatore=0.85,
  Ahmedabad=0.88, Jaipur=0.83, Kolkata=0.88, Indore=0.82,
  Thiruvananthapuram=0.87, Visakhapatnam=0.83, Nagpur=0.82, Chandigarh=0.85,
  London=2.20, Toronto=1.90, Singapore=2.00, Dubai=1.80, `New York`=2.30, Berlin=1.95
)

# Company size premium
size_premium <- c(Small=0.85, Medium=1.00, Large=1.12, Enterprise=1.25)

# Industry premium
ind_premium <- c(
  "Information Technology"=1.10, "Banking & Finance"=1.15, "E-Commerce"=1.08,
  "Healthcare"=0.95, "Telecommunications"=1.00, "Manufacturing"=0.92,
  "Consulting"=1.05, "EdTech"=0.90, "Logistics"=0.90, "Media & Entertainment"=0.93
)

# ---------------------------------------------------------------------------
# 4. GENERATE RECORDS
# ---------------------------------------------------------------------------

cat("Generating", N, "job posting records...\n")

# Sample titles
titles <- sample(job_titles, N, replace=TRUE, prob=title_weights)

# Sample locations
loc_all    <- c(locations_india, locations_intl)
loc_prob   <- c(loc_india_weights, loc_intl_weights)
loc_chosen <- sample(loc_all, N, replace=TRUE, prob=loc_prob)

# States / countries
state_map  <- c(setNames(states_india, locations_india), setNames(states_intl, locations_intl))
country_map <- c(setNames(rep("India", length(locations_india)), locations_india),
                 setNames(c("UK","Canada","Singapore","UAE","USA","Germany"), locations_intl))
states   <- state_map[loc_chosen]
countries <- country_map[loc_chosen]

# Industries, employment, education, remote, size, company
industries_col <- sample(industries, N, replace=TRUE, prob=industry_weights)
emp_col        <- sample(employment_types, N, replace=TRUE, prob=emp_weights)
edu_col        <- sample(education_levels, N, replace=TRUE, prob=edu_weights)
remote_col     <- sample(remote_types, N, replace=TRUE, prob=remote_weights)
size_col       <- sample(company_sizes, N, replace=TRUE, prob=size_weights)
company_col    <- sample(all_companies, N, replace=TRUE)

# Experience years — depends on title cluster
exp_ranges <- list(
  junior  = 0:2,
  mid     = 2:5,
  senior  = 5:10,
  lead    = 8:18
)
# Internships are always 0 exp; others drawn from weighted range
experience_col <- sapply(seq_len(N), function(i) {
  if (emp_col[i] == "Internship") return(0L)
  r <- runif(1)
  if (r < 0.25)       sample(0:2, 1)
  else if (r < 0.55)  sample(2:5, 1)
  else if (r < 0.80)  sample(5:10, 1)
  else                sample(8:18, 1)
})

# Skills — per-title pool + optional soft skills
generate_skills <- function(title) {
  pool    <- skill_pools[[title]]
  n_pick  <- sample(4:min(10, length(pool)), 1)
  picked  <- sample(pool, n_pick)
  # 40% chance to add 1-2 soft skills
  if (runif(1) > 0.6) {
    picked <- c(picked, sample(soft_skills, sample(1:2, 1)))
  }
  paste(unique(picked), collapse=";")
}
skills_col <- sapply(titles, generate_skills)
skill_count_col <- sapply(strsplit(skills_col, ";"), length)

# Salary generation — statistically plausible
salary_inr_col <- mapply(function(title, loc, size, ind, yrs, emp) {
  base <- base_salary_lpa[title]
  s    <- base *
    exp_premium(yrs) *
    (loc_premium[loc] %||% 1.0) *
    (size_premium[size] %||% 1.0) *
    (ind_premium[ind] %||% 1.0)
  # Add gaussian noise (±15%)
  s <- s * rnorm(1, mean=1, sd=0.12)
  # Internship override
  if (emp == "Internship") s <- runif(1, 0.8, 2.5)
  # Convert to absolute INR (lakhs × 100000)
  s_inr <- round(s * 100000)
  pmax(s_inr, 60000)  # floor ₹60,000/year
}, titles, loc_chosen, size_col, industries_col, experience_col, emp_col)

# salary_min / salary_max — derived from salary_inr with ±10%
salary_min_col <- round(salary_inr_col * runif(N, 0.88, 0.96))
salary_max_col <- round(salary_inr_col * runif(N, 1.04, 1.14))

# posted_date — last 18 months
start_date <- as.Date("2025-04-01")
end_date   <- as.Date("2026-10-01")
posted_col <- sample(seq(start_date, end_date, by="day"), N, replace=TRUE)

# Simple job descriptions (short, role-appropriate)
desc_templates <- c(
  "We are looking for an experienced %s to join our growing team. You will work on challenging problems and collaborate with cross-functional teams.",
  "Seeking a motivated %s with strong analytical and problem-solving skills. Must have hands-on experience with relevant technologies.",
  "Join our dynamic team as a %s. You will be responsible for design, development, and maintenance of our core systems.",
  "Exciting opportunity for a %s to work in a fast-paced environment. Prior experience in Agile methodologies preferred.",
  "We are hiring a %s to contribute to our technical roadmap. Strong communication and teamwork skills are essential."
)
jd_col <- sprintf(sample(desc_templates, N, replace=TRUE), titles)

# job_id
job_id_col <- paste0("JB", sprintf("%05d", seq_len(N)))

# ---------------------------------------------------------------------------
# 5. ASSEMBLE DATA FRAME
# ---------------------------------------------------------------------------

df <- data.frame(
  job_id          = job_id_col,
  job_title       = titles,
  company         = company_col,
  location        = as.character(loc_chosen),
  state           = as.character(states),
  country         = as.character(countries),
  industry        = industries_col,
  employment_type = emp_col,
  experience_years= experience_col,
  education       = edu_col,
  salary_min      = salary_min_col,
  salary_max      = salary_max_col,
  salary_currency = ifelse(countries == "India", "INR", "USD"),
  salary_inr      = salary_inr_col,
  skills          = skills_col,
  skill_count     = skill_count_col,
  posted_date     = posted_col,
  remote_type     = remote_col,
  company_size    = size_col,
  job_description = jd_col,
  stringsAsFactors = FALSE
)

# ---------------------------------------------------------------------------
# 6. INTRODUCE REALISTIC IMPERFECTIONS
# ---------------------------------------------------------------------------

n <- nrow(df)

# Helper: randomly set ~p% of column to NA
add_missing <- function(col, p) {
  idx <- sample(seq_len(n), size=round(n * p))
  col[idx] <- NA
  col
}

# Missing values
df$salary_inr[sample(n, round(n * 0.030))] <- NA
df$education  <- add_missing(df$education,   0.022)
df$company_size <- add_missing(df$company_size, 0.018)
df$skills     <- add_missing(df$skills,       0.012)
df$location   <- add_missing(df$location,     0.015)
df$salary_min[sample(n, round(n * 0.025))] <- NA
df$salary_max[sample(n, round(n * 0.025))] <- NA

# Inconsistent capitalization (~2% of job_title)
cap_idx <- sample(n, round(n * 0.02))
df$job_title[cap_idx] <- toupper(df$job_title[cap_idx])

# Extra whitespace in company (~1.5%)
ws_idx <- sample(n, round(n * 0.015))
df$company[ws_idx] <- paste0(" ", df$company[ws_idx], "  ")

# Mixed case location (~1%)
ml_idx <- sample(n, round(n * 0.01))
df$location[ml_idx] <- tolower(df$location[ml_idx])

# Duplicate rows (~0.5%)
n_dupes <- round(n * 0.005)
dupe_src <- sample(seq_len(n), n_dupes)
dupes    <- df[dupe_src, ]
dupes$job_id <- paste0(dupes$job_id, "_DUP")
df <- rbind(df, dupes)

# A few outlier salaries (very high — realistic for niche roles)
outlier_idx <- sample(nrow(df), 8)
df$salary_inr[outlier_idx] <- df$salary_inr[outlier_idx] * runif(8, 2.5, 4.0)

# Shuffle
df <- df[sample(nrow(df)), ]
rownames(df) <- NULL

# ---------------------------------------------------------------------------
# 7. SAVE
# ---------------------------------------------------------------------------

out_path <- "data/job_market.csv"
if (!dir.exists("data")) dir.create("data", recursive=TRUE)

write.csv(df, out_path, row.names=FALSE)
cat("Dataset saved:", out_path, "\n")
cat("Rows:", nrow(df), "| Columns:", ncol(df), "\n")
cat("Missing salary_inr:", sum(is.na(df$salary_inr)), "\n")
cat("Done.\n")
