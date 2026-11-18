# =============================================================================
# scripts/start-plumber.R
# Script to launch the CareerLens R Plumber API service on port 8001
# =============================================================================

suppressPackageStartupMessages(library(plumber))

port <- as.numeric(Sys.getenv("CAREERLENS_PLUMBER_PORT", "8001"))
host <- Sys.getenv("CAREERLENS_PLUMBER_HOST", "127.0.0.1")

pr <- plumb("api/plumber.R")
message(sprintf("[Plumber] Starting CareerLens R Analytics Service on http://%s:%d ...", host, port))
pr$run(host = host, port = port, swagger = FALSE)
