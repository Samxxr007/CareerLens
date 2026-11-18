import { app } from "./app.js";
import { config } from "./config/env.js";
import { rPlumberService } from "./services/rPlumber.service.js";

const server = app.listen(config.port, async () => {
  console.log(`[CareerLens Node Backend] Running on http://localhost:${config.port}`);
  console.log(`[CareerLens Node Backend] Connected to R Plumber at ${config.rPlumberUrl}`);
  
  // Initial health ping to R service
  const rHealth = await rPlumberService.checkHealth();
  console.log(`[CareerLens Node Backend] R Service Status:`, rHealth.status || "unreachable");
});

process.on("SIGINT", () => {
  server.close(() => {
    console.log("[CareerLens Node Backend] Shutting down gracefully...");
    process.exit(0);
  });
});
