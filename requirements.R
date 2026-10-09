# =============================================================================
# requirements.R
# CareerLens — ITA04: Statistics with R Programming
# -----------------------------------------------------------------------------
# Run this script once before launching the app to install any missing packages.
# Usage (in RStudio Console):
#   source("requirements.R")
# =============================================================================

options(timeout = 600)

required_packages <- c(
  "shiny",       # Core Shiny framework
  "bslib",       # Bootstrap 5 theming
  "dplyr",       # Data manipulation
  "tidyr",       # Data reshaping
  "ggplot2",     # Static visualisations
  "plotly",      # Interactive charts
  "readr",       # Fast CSV reading/writing
  "stringr",     # String operations
  "DT",          # Interactive data tables
  "scales",      # Number formatting helpers
  "corrplot"     # Correlation matrix plots
)

cat("Checking required packages...\n")

to_install <- required_packages[!required_packages %in% installed.packages()[, "Package"]]

if (length(to_install) > 0) {
  cat("Installing missing packages:", paste(to_install, collapse=", "), "\n")
  for (pkg in to_install) {
    if (!pkg %in% installed.packages()[, "Package"]) {
      cat("\n>>> Installing", pkg, "...\n")
      install.packages(pkg, repos="https://cloud.r-project.org", dependencies=c("Depends", "Imports", "LinkingTo"))
    }
  }
  
  # Check if any still missing
  still_missing <- required_packages[!required_packages %in% installed.packages()[, "Package"]]
  if (length(still_missing) > 0) {
    cat("\nWarning: Some packages could not be installed automatically:", paste(still_missing, collapse=", "), "\n")
  } else {
    cat("\nInstallation complete. All packages verified successfully.\n")
  }
} else {
  cat("All packages are already installed. No action needed.\n")
}

cat("Ready. Launch the app with: shiny::runApp()\n")
