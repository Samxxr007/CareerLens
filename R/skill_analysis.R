# =============================================================================
# skill_analysis.R
# CareerLens — ITA04: Statistics with R Programming
# -----------------------------------------------------------------------------
# Functions:
#   parse_skills()           - explode skills column to long format
#   calculate_skill_demand() - frequency table with rank and demand %
#   role_skill_demand()      - skills filtered by job title
#   location_skill_demand()  - skills filtered by location
#   get_skill_category()     - tags each skill as Technical/Cloud/Soft/Tool/etc.
# =============================================================================

# -----------------------------------------------------------------------------
# get_skill_category()
# Returns the category of a skill as a character string
# -----------------------------------------------------------------------------
get_skill_category <- function(skill) {
  skill <- trimws(as.character(skill))

  cloud_skills   <- c("AWS","Azure","GCP","Terraform","Kubernetes","Docker",
                       "Ansible","CI/CD","Jenkins","Kubernetes","Airflow","Kafka")
  data_skills    <- c("SQL","MySQL","PostgreSQL","MongoDB","Oracle DB","Redis",
                       "Spark","Hadoop","dbt","Elasticsearch")
  ml_skills      <- c("TensorFlow","PyTorch","scikit-learn","MLflow","Pandas",
                       "NumPy","Statistics","Jupyter","R","Matplotlib","Tableau",
                       "Power BI","Google Analytics","A/B Testing")
  lang_skills    <- c("Python","Java","JavaScript","TypeScript","C++","C#",
                       "Bash","Shell Scripting","Go","Scala","Rust")
  web_skills     <- c("React","Angular","Vue","Node.js","Express","Django",
                       "Flask","FastAPI","Spring Boot","HTML","CSS","Redux",
                       "REST API","GraphQL","REST Assured","Tailwind CSS","Postman")
  tool_skills    <- c("Git","GitHub","Jira","Agile","Figma","Adobe XD","Sketch",
                       "Selenium","Cypress","TestNG","Maven","Hibernate","JUnit",
                       "MS Office","Excel","Visio","MS Project","Canva")
  soft_skills    <- c("Communication","Teamwork","Problem Solving","Leadership",
                       "Time Management","Stakeholder Management","Documentation",
                       "UX Research","Prototyping","Wireframing","Product Management",
                       "Roadmapping","Requirements Analysis","Product Strategy",
                       "Customer Support","Troubleshooting","Manual Testing")
  security_skills <- c("Network Security","SIEM","Firewalls","Vulnerability Assessment",
                        "Ethical Hacking","Wireshark","ISO 27001")
  infra_skills   <- c("Linux","Windows Server","Networking","VMware","Active Directory",
                       "Backup & Recovery","Performance Tuning","Monitoring")

  dplyr::case_when(
    skill %in% cloud_skills    ~ "Cloud & DevOps",
    skill %in% data_skills     ~ "Database & Data",
    skill %in% ml_skills       ~ "Analytics & ML",
    skill %in% lang_skills     ~ "Programming Languages",
    skill %in% web_skills      ~ "Web & Frameworks",
    skill %in% tool_skills     ~ "Tools & Practices",
    skill %in% soft_skills     ~ "Soft Skills",
    skill %in% security_skills ~ "Security",
    skill %in% infra_skills    ~ "Infrastructure",
    TRUE                       ~ "Other"
  )
}

# -----------------------------------------------------------------------------
# parse_skills()
# Takes the cleaned data frame, explodes skills column into long format.
# Returns: data frame with columns: job_id, job_title, location, skill
# -----------------------------------------------------------------------------
parse_skills <- function(df) {
  df_skills <- df |>
    dplyr::select(job_id, job_title, location, industry, employment_type, skills) |>
    dplyr::filter(!is.na(skills), nzchar(trimws(skills))) |>
    tidyr::separate_rows(skills, sep=";") |>
    dplyr::mutate(skill = trimws(skills)) |>
    dplyr::filter(nzchar(skill)) |>
    dplyr::select(-skills)

  df_skills$skill_category <- get_skill_category(df_skills$skill)
  df_skills
}

# -----------------------------------------------------------------------------
# calculate_skill_demand()
# Returns ranked skill frequency table from the full dataset
# -----------------------------------------------------------------------------
calculate_skill_demand <- function(df) {
  total_jobs <- nrow(df)

  df_long <- parse_skills(df)

  df_long |>
    dplyr::count(skill, skill_category, name="job_count") |>
    dplyr::mutate(
      demand_pct = round(job_count / total_jobs * 100, 1),
      rank       = rank(-job_count, ties.method="min")
    ) |>
    dplyr::arrange(rank)
}

# -----------------------------------------------------------------------------
# role_skill_demand()
# Top skills for a given job title
# -----------------------------------------------------------------------------
role_skill_demand <- function(df, target_role, top_n = 15) {
  role_df    <- df |> dplyr::filter(as.character(job_title) == target_role)
  role_total <- nrow(role_df)
  if (role_total == 0) return(data.frame())

  parse_skills(role_df) |>
    dplyr::count(skill, skill_category, name="job_count") |>
    dplyr::mutate(
      demand_pct = round(job_count / role_total * 100, 1),
      rank       = rank(-job_count, ties.method="min")
    ) |>
    dplyr::arrange(rank) |>
    dplyr::slice_head(n=top_n)
}

# -----------------------------------------------------------------------------
# location_skill_demand()
# Top skills for a given location
# -----------------------------------------------------------------------------
location_skill_demand <- function(df, target_location, top_n = 15) {
  loc_df    <- df |> dplyr::filter(location == target_location)
  loc_total <- nrow(loc_df)
  if (loc_total == 0) return(data.frame())

  parse_skills(loc_df) |>
    dplyr::count(skill, skill_category, name="job_count") |>
    dplyr::mutate(
      demand_pct = round(job_count / loc_total * 100, 1),
      rank       = rank(-job_count, ties.method="min")
    ) |>
    dplyr::arrange(rank) |>
    dplyr::slice_head(n=top_n)
}
