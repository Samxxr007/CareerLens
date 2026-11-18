# =============================================================================
# validate.R — CareerLens End-to-End Validation Script
# ITA04: Statistics with R Programming
# Run this to verify project integrity before demonstration:
#   Rscript validate.R
# =============================================================================

cat("=== CareerLens Validation Starting ===\n\n")

# Run the comprehensive test suite
source("tests/test_functions.R")

cat("\n=== Validating Shiny Application Initialization ===\n")
app_obj <- source("app.R")
stopifnot("Shiny App failed to initialize" = inherits(app_obj$value, "shiny.appobj"))

cat("  [PASS] app.R successfully parsed and initialized as shiny.appobj\n")
cat("\n===================================================================\n")
cat("   ALL CAREERLENS VALIDATION CHECKS PASSED!\n")
cat("   To launch in RStudio: shiny::runApp()\n")
cat("===================================================================\n")
